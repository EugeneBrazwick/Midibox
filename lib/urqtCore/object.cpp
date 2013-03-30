
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

//#define TRACE

#pragma implementation
#include <QtCore/QTextStream>
#include <QtCore/QQueue>
#include "api_utils.h"
#include "time_model.h"
#include "margins.h"
#include "size.h"
#include "ruby++/array.h"
#include "ruby++/hash.h"
#include "ruby++/proc.h"
#include "ruby++/bool.h"
#include "object.h"
#include "signalproxy.moc.h"

namespace R_Qt {

RPP::Module 
mQt,
mR,
mReform;

RPP::Class
cSynthObject,
cDynamicAttribute,
cReformError,
cModel
;

RPP::Class
eReform
;

//typedef RPP::DataObject<QObject> RPP_QObject;

/* SIGNALS
 * =========
 *
 * require a proxy since our slots are ruby functions.
 *
 * Where do we store them?
 *
 * x.connect('f(qBLA)') { y.g } 
 * -> 
 *			   new proxy('f(qBLA)', block)
 *			   v_proxy = proxy.wrap
 *			   x.proxies << v_proxy
 *			   qx->connect(qtSIGNAL('f(qBLA)'), proxy, SLOT(handle(qBLA)))
 *
 * VALUE cklass_f(BLA)
 *   qself->f(qBLA)
 * end
 *
 * But what about BLA vs qBLA?
 * I don't want handlers for different types, but the C handlers will
 * take different types.
 * NOT THIS:
 *    void handle(int a);
 *    void handle(int a, int b);
 *    void handle(int a, const QString &b);
 *    void handle(const QString &a);
 *    .... ??
 *
 * Can we easily use VALUE or RValue?
 * 
 * class QSignalProxy: public QObject
 * {
 *   VALUE Block; // must be gc'ed !
 *   Q_OBJECT
 *
 *     QSignalProxy(const char *signal, VALUE v_block):	
 *	 Block(v_block)
 *       {
 *	    ...
 *	    connect('call(RValue)', this, 'handle(RValue)');
 *       }
 *   signals:
 *      void call(const RValue &v);
 *   slots:
 *      void handle(const RValue &v)
 *	  {
 *	    Block.call(*v)
 *	  }
 * };
 *
 * // each connect requires a new signalproxy
 * def connect qsigstr, &block
 *   @proxies[qsigstr] << SignalProxy.new('2' + qsigstr, block)
 * end
 *
 * def emit qsigstr, *args
 *   @proxies[qsigstr].each {|p| p.call(args) } 
 * end
 *
 * def f *args
 *   emit 'f(VALUE)', *args
 * end
 *
 * // Qt may queue signals. If they are carrying VALUE's this may be deadly...
 *
 * But we have RGCGuardedValue (see alsa code) and signals are temporary
 * for sure.
 *
 * Uh Oh.....
 * ==========
 *
 * MAJOR DESIGN FAILURE
 * To connect a Qt signal we need a slot with the same signature.
 * But we don't have that!
 *
 * Can be fixed. But we need g++, moc and ld support at RUNTIME!!
 *
 */

/* delete of object will also delete all subs.
 * So any ruby reference into it must die!
 *
 * We cannot use 'self.children' or 'self.each_child' 
 * since that would skip trees that may still contain ruby values.
 *
 * However we can use each_sub!
 * But then again, there is no need to do so, since 'delete'
 * will not delete these anyway.
 * Hm.... Technically it SHOULD. But note that both
 * 'app' and 'scene' have pseudo-children. But the Qt API
 * will in fact delete the scene children!
 * So do not touch.
 */
static void
zombify(QObject *qobject)
{
  trace2("zombify(%s %p)", QTCLASS(qobject), qobject);
  const RPP::QObject<QObject> object(qobject, RPP::VERYUNSAFE);
  if (!object.isNil()) object.zombify();
  const QObjectList &children = qobject->children(); // not object!!
  foreach (QObject *child, children) 
    // If the object is OWNED by ruby, do NOT let Qt free it (at least here)
    zombify(child);
}

 /** 
  * zombify the ENTIRE tree.
  *
  * In the end call 'delete qt-object'
  * This will remove the item properly from its parent as well
  * AND it will delete all containing children recursively.
  *
  * Any ruby references to items inside the tree that are themselves
  * outside the tree are 'zombified', but otherwise it is perfectly harmless.
  * As long as you don't use clone or dup that is. Woe will be on you!
  * But actually dup and clone on Qt::Object must be disabled!
  */
static VALUE 
cObject_delete(VALUE v_self)
{
  track1("%s.delete", v_self);
  if (IS_ZOMBIFIED(v_self)) return Qnil;
  const RPP::QObject<QObject> self(v_self);
  trace4("cObject_delete(qptr=%p, class=%s, name='%s', #children=%d)", &self, 
	 self.qtclass(), qString2cstr(self->objectName()),
	 self->children().count());
  track1("Freeing ruby VALUE %s", self);
  zombify(self);
  delete &self;
  return Qnil;
}

// Does not use QObject, but must be C++
/** :call-seq:
 *	  zombified? -> bool
 * 
 * Returns:
 *    true if the C++ object belonging to this ruby-instance was deleted.
 */
static VALUE 
cObject_zombified_p(VALUE v_self)
{
  return p(IS_ZOMBIFIED(v_self));
}

/*
 *  app {
 *    mainwindow {
 *    }
 *  }
 *
 * How is this stored?
 *
 * QApp(property:R_Qt::RValue vApp)
 *    QObjectList children [
 *	[0] -> QMainWindow(property:R_Qt::RValue vMainWindow)
 *    ]
 */
void
cObject_mark(QObject *object)
{
  if (!object) return;
  trace1("cObject_mark(qptr=%p)", object);
  trace2("class=%s, #children=%d)", 
	 object->metaObject()->className(), object->children().count());
  foreach (QObject *child, object->children())
    {
      const RPP::QObject<QObject> v_child(child, RPP::VERYUNSAFE);
      if (!v_child.isNil()) v_child.gc_mark();
    }
  foreach (const QByteArray &propname, object->dynamicPropertyNames())
    {
      // does it start with 'R_Qt::' ?
      if (strncmp(propname.data(), R_QT_INTERNAL_PROPERTY_PREFIX, 
		  strlen(R_QT_INTERNAL_PROPERTY_PREFIX)) != 0) 
	continue;
      const QVariant &var = object->property(propname);
      if (var.canConvert<RValue>())
	RPP::BasicObject(var.value<RValue>()).gc_mark();
    }
}

static VALUE
cObject_alloc(VALUE cObject)
{
  trace("cObject_alloc");
  return RPP::QObject<QObject>(cObject, new QObject);
}

/** aka 'auto-delete'
 *
 * After being called the C++ QObject is deleted whenever
 * the ruby object goes out of scope (actually when it is gc-ed).
 *
 * Note that this method throws for any non-QObjects
 * (see control.rb  NoQtControl#takeOwnership).
 * 
 * Common usage: when a QObject is added to a non-QObject which
 * is supposed to 'own' it.  Qt's own delete-mechanism cannot be used
 * in such cases.
 */
static VALUE
cObject_takeOwnership(VALUE v_self)
{
  RPP::QObject<QObject>(v_self).takeOwnership();
  return Qnil;
}

/** :call-seq:
 *	objectName = string
 *	objectName = symbol
 *	objectName = nil, to clear (same as '')
 */
static VALUE
cObject_objectName_set(VALUE v_self, VALUE v_newname)
{
  const RPP::QObject<QObject> self = v_self;
  self.check_frozen();
  const RPP::String newname = v_newname;
  self->setObjectName(newname.to_s());
  return v_newname;
}

static VALUE
cObject_mark_ownership(VALUE v_self)
{
#if defined(DEBUG)
  QObject * const self = 
#endif
			 v2qt(v_self); 
#if defined(DEBUG)
  trace("DEBUG: cObject_mark_ownership, stored v_self in Property, do a reverse check");
  const VALUE vdbg = qt2v(self);
  trace1("DEBUG: vdbg=%p", (void *)vdbg);
  if (vdbg != v_self)
    rb_raise(rb_eFatal, "programming error qt2v <-> v2qt MISMATCH");
#endif
  return Qnil;
}

/** :call-seq: qtparent= newParent
 *
 * The object is always removed from the children list of the old
 * parent (if set).
 * If newParent is nil nothing else happens.
 * Otherwise the object is added to the 'children' list of parent.
*/
static VALUE 
cObject_qtparent_set(VALUE v_self, VALUE v_parent)
{
  trace("cObject_qtparent_set");
  track2("cObject_qtparent_set(%s, %s)", v_self, v_parent);
  const RPP::QObject<QObject> self = v_self;
  self.check_frozen();
  QObject *parent = 0;
  if (!NIL_P(v_parent))
    {
      trace("retrieve QObject");
      GET_STRUCT_NODECL(QObject, parent);
    }
  trace("retrieve self");
  trace("Calling setParent");
  self->setParent(parent);
  return v_parent;
}

static VALUE
cObject_qtparent_get(VALUE v_self)
{
  trace("cObject_qtparent_get");
  const RPP::QObject<QObject> self = v_self;
  return qt2v(self->parent());
}

/** :call-seq:
 *	objectName -> string or nil
 *
 * Returns nil for empty strings, which seems more convenient.
 */
static VALUE
cObject_objectName_get(VALUE v_self)
{
  const RPP::QObject<QObject> self = v_self;
  return qString2v_nil(self->objectName());
}

static VALUE
cObject_qtchildren_get(VALUE v_self)
{
  const RPP::QObject<QObject> self = v_self;
  trace1("%s::children_get", self.to_s());
  const QObjectList &children = self->children();
  const RPP::Array r(children.count());
  foreach (QObject *child, children) // foreach is delete/remove-safe!
    {
      const RPP::QObject<QObject> v_child(child, RPP::VERYUNSAFE);
      if (!v_child.isNil()) r.push(v_child);
    }
  return r;
}

static VALUE
cObject_qtchildren_set(int argc, VALUE *argv, VALUE v_self)
{
  const RPP::QObject<QObject> self = v_self;
  trace2("%s::children_set, argc=%d", self.to_s(), argc);
  const QObjectList &oldchildren = self->children();
  self.check_frozen();
  VALUE v_children;
  rb_scan_args(argc, argv, "*", &v_children);
  RPP::Array children(v_children, RPP::UNSAFE);
  trace1("RARRAY_LEN=%ld", children.len());
  RPP::Array t;
  if (children.len() == 1) t = RPP::Object(children.entry(0)).check_array_type();
  if (t.test()) children = t;
  track1("v_children='%s'", children);
  trace1("assigning children, #oldchildren=%d", oldchildren.count());
  foreach (QObject *child, oldchildren)
    {
      trace1("setParent to 0 on child %p", child);
      child->setParent(0);
    }
  trace("rb_check_array_type");
  track1("v_children='%s'", children);
  const long N = children.len();
  trace1("N=%ld", N);
  long i = 0;
  for (VALUE *v_child = children.ptr(); i < N; i++, v_child++)
    {
      const RPP::QObject<QObject>child = *v_child;
      child->setParent(self);
    }
  return v_children;
} // cObject_qtchildren_set

/* SUBTLETY:
 * A tree that has a non-ruby root may still hold ruby leaves!
 * So on our search we cannot use NIL_P(v_child) to skip enqueueing.
 *
 * And also we must enqueue QObject* and not VALUE.
 *
 * Similarly we cannot use 'each_child' since it only can enumerate
 * VALUEs.
 * 
 * QObject specific! QGraphicsItem needs overrides!!
 *
 * with v_queue is Qnil it yields ruby wrapped children. And we can use it for
 * each_child. With an Array we can use it for each_sub.  Clever, nah?
 *
 * NOTE: v_self is always a QObject* 'fake' wrapper. Do not call virtual ruby methods
 * on it!
 * However, overriden methods do not suffer from this as they can only be called
 * if their wrapper is not a cObject to begin with.
 *
 * NOTE: do not use RETURN_ENUMERATOR here. This method is not supposed to be called
 * directly!
 */
static VALUE 
cObject_enqueue_children(int argc, VALUE *argv, VALUE v_self)
{
  trace("cObject_enqueue_children");
  VALUE v_queue;
  rb_scan_args(argc, argv, "01", &v_queue);
  track2("%s::enqueue_children(%s)", v_self, v_queue);
  const RPP::QObject<QObject> self = v_self;
  const QObjectList &children = self->children();
  trace1("#children = %d", children.count());
  const bool yield = NIL_P(v_queue);
  foreach (QObject *child, children)
    {
      const RPP::Object v_child = qt2v(child);
      if (yield)
	{
	  if (!v_child.isNil()) v_child.yield();
	}
      else
	{
	  const RPP::Array queue = v_queue;
	  if (v_child.isNil())
	    queue.push(Data_Wrap_Struct(cSynthObject, 0, 0, child));
	  else
	    queue.push(v_child);
	}
    }
  return Qnil;
}

/** :call-seq:
 *	self connect(:symbol, proc)
 *	self connect(qt_signal_str, proc)
 *
 * INTERNAL USE.   Simply use '	  signal 'timeout()' to create + connect to the Qt 'timeout' signal
 * See below.
 *
 * The first one is ruby only.
 * The second one connects the Qt signal and is C only.
 * the '2' prefix must be removed, so it looks like:  
 *	obj.connect('destroyed(QObject *)', proc)
 *
 * However, there is no need to use connect to achieve this.
 *
 * 1) declare the signal:	signal 'editingFinished()'
 * 2) connect it:		editingFinished do .... end
 * 3) emit it:			editingFinished
 */
static VALUE 
cObject_connect(VALUE v_self, VALUE v_signal, VALUE v_proc)
{
  const RPP::QObject<QObject> self = v_self;
  self.check_frozen();
  const RPP::Symbol signal(v_signal, RPP::VERYUNSAFE);
  track1("cObject_connect, signal=%s", signal);
  track3("cObject_connect %s, %s, %s", self, signal, v_proc);
  if (signal.isSymbol())
    {
      // ((@connections ||= {})[symbol] ||= []) << block
      RPP::Hash connections(self.iv("@connections"), RPP::VERYUNSAFE);
      if (!connections.isHash())
	self.iv_set("@connections", connections = RPP::Hash());
      RPP::Array proxylist(connections[v_signal], RPP::VERYUNSAFE);
      if (!proxylist.isArray())
	connections[signal] = proxylist = RPP::Array();
      proxylist.push(v_proc);
      return Qnil;
    }
  const char * const signalname = signal.to_s();
  trace1("native Qt signal '%s'", signalname);
  new QSignalProxy(self, signalname, v_proc); 
  return v_self;
}

static VALUE
cObject_widget_p(VALUE v_self)
{
  const RPP::QObject<QObject> self = v_self;
  trace1("cObject_widget_p, isWidgetType -> %d", self->isWidgetType());
  return RPP::Bool(self->isWidgetType());
}

static VALUE
cObject_setProperty(VALUE v_self, VALUE v_name, VALUE v_value)
{
  const RPP::QObject<QObject> self = v_self;
  self->setProperty(RPP::String(v_name), QVariant::fromValue(RValue(v_value))); 
  return v_value;
}

static VALUE
cObject_property(VALUE v_self, VALUE v_name)
{
  const RPP::QObject<QObject> self = v_self;
  return prop2v(self, RPP::String(v_name));
}

static VALUE
init_object()
{
  trace("init_object");
  cObject.define_alloc_func(cObject_alloc)
	 .define_method("qtparent_get", cObject_qtparent_get)
	 .define_method("qtparent", cObject_qtparent_get)
	 .define_method("qtparent=", cObject_qtparent_set)
	 .define_method("qtchildren_get", cObject_qtchildren_get)
         .define_method("qtchildren=", cObject_qtchildren_set)
	 .define_method("objectName_get", cObject_objectName_get)
	 .define_method("objectName=", cObject_objectName_set)
	 .define_method("delete", cObject_delete)
	 .define_method("zombified?", cObject_zombified_p)
	 .define_method("widget?", cObject_widget_p)
	 .define_private_method("connect", cObject_connect)
	 .define_private_method("mark_ownership", cObject_mark_ownership)
	 .define_method("enqueue_children", cObject_enqueue_children)
	 .define_method("takeOwnership", cObject_takeOwnership)
	 .define_method("setProperty", cObject_setProperty)
	 .define_method("property", cObject_property)
	 ;
  trace("init_object OK");
  return cObject;
}

/** :call-seq: tr(source, [disambiguation = '',] count = -1)
 *
 * Note that the encoding must be utf-8
 */
static VALUE 
mReform_tr(int argc, VALUE *argv, VALUE/*v_self*/)
{
  VALUE v_source, v_disambiguation, v_count;
  rb_scan_args(argc, argv, "12", &v_source, &v_disambiguation, &v_count);
  track3("mReform_tr(%s, %s, %s)", v_source, v_disambiguation, v_count);
  const RPP::String t = RPP::Object(v_count).check_string_type();
  if (t.test())
    {
      // swap
      v_count = v_disambiguation;
      v_disambiguation = t;
    }
  const RPP::String disambiguation = v_disambiguation;
  const RPP::Fixnum count = v_count;
#define IGNORE_THIS_TR trUtf8
  return qString2v(QObject::IGNORE_THIS_TR(RPP::String(v_source), 
					   disambiguation.isNil() ? 0 : disambiguation.to_s(),
					   count.isNil() ? -1 : count.to_i()));
}

static inline void
init_qt()
{
  trace("init_qt");
  mR = RPP::Module("R");
  const RPP::Module mReform = mR.define_module("EForm");
  mQt = mR.define_module("Qt");
  cObject = mQt.define_class("Object", rb_cObject);
  cReformError = mReform.define_class("Error", rb_eRuntimeError);
  init_size(mQt);
  init_margins(mQt);
}

static inline void
init_control()
{
  cControl = mQt.define_class("Control", cObject);
  cControl.define_const( "DynValProp", R_QT_DYNVALUE_PROPERTYID);
  cDynamicAttribute = mQt.define_class("DynamicAttribute", cControl);
}

static void
init_noqtcontrol()
{
  cNoQtControl = mQt.define_class("NoQtControl", cControl);
}

static inline void
init_synthobject()
{
  cSynthObject = mQt.define_class("SynthObject", cObject);
}

void 
cObject_signal_impl(VALUE v_self, const char *method, VALUE v_args, 
		    VALUE v_block)
{
  const RPP::Symbol v_method = method;
  const RPP::Object self = v_self;
  self.call("signal_implementation", v_method, v_method, v_args, v_block);
}

} // namespace R_Qt 

using namespace R_Qt;

void
Init_liburqtCore()
{
  static bool loaded = false;
  trace1("Init_liburqtCore, loaded=%d", loaded);
  if (loaded) return;
  init_qt(); // mR + mQt + cObject
  mReform = mR.define_module("EForm");
  mReform.define_function("tr", mReform_tr);
  eReform = mR.define_class("Error", rb_eRuntimeError);
  init_rvalue(); // assigns RVALUE_ID
  init_object();
  init_control(); // cControl + cDynamicAttribute
  init_noqtcontrol(); // cNoQtControl
  init_synthobject(); // cSynthObject
  cModel = mQt.define_class("Model", cControl);
  init_time_model(mQt, cModel);
  loaded = true;
  trace("Init_liburqtCore OK");
}

