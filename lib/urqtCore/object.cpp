
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

//#define TRACE

#pragma implementation
//  #include "ruby++/ruby++.h"	FAILBUNNY aka CRASHBUNNY
#include <QtCore/QTextStream>
#include "api_utils.h"
#include "object.h"
#include "signalproxy.moc.h"

namespace R_Qt {

VALUE mR = Qnil, mQt = Qnil;

//typedef RPP::DataObject<QObject> RPP_QObject;

/* delete of object will also delete all subs.
 * So any ruby reference into it must die!
 */
static void
zombify(QObject *object)
{
  const VALUE v_object = qt2v(object);
  if (!NIL_P(v_object))
    {
      trace("zombify child");
      ZOMBIFY(v_object);
    }
  traqt1("%s::children", QTCLASS(object));
  const QObjectList &children = object->children();
  foreach (QObject *child, children) 
    {
      trace1("ITER: cObject.child %s", child->metaObject()->className());
      // If the object is OWNED by ruby, do NOT let Qt free it (at least here)
      zombify(child);
    }
}

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

static void 
cObject_delete(VALUE v_self)
{
  if (IS_ZOMBIFIED(v_self)) return;
  RQTDECLSELF(QObject);
  trace4("cObject_free(qptr=%p, class=%s, name='%s', #children=%d)", self, 
	 self->metaObject()->className(), qString2cstr(self->objectName()),
	 self->children().count());
  track1("Freeing ruby VALUE %s", v_self);
  zombify(self);
  traqt2("delete %s(%p)", QTCLASS(self), self);
  delete self;
}

// Does not use QObject
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
  traqt1("%s::children", QTCLASS(object));
  foreach (QObject *child, object->children())
    {
      const VALUE vChild = qt2v(child);
      if (!NIL_P(vChild))
	rb_gc_mark(vChild);
    }
  traqt1("%s::dynamicPropertyNames", QTCLASS(object));
  foreach (const QByteArray &propname, object->dynamicPropertyNames())
    {
      traqt2("%s::property(%s)", QTCLASS(object), propname.data());
      const QVariant &var = object->property(propname);
      if (var.canConvert<RValue>())
	rb_gc_mark(var.value<RValue>());
    }
}

/** :call-seq: parent= newParent
 *
 * The object is always removed from the children list of the old
 * parent (if set).
 * If newParent is nil nothing else happens.
 * Otherwise the object is added to the 'children' list of parent.
*/
static VALUE 
cObject_parent_assign(VALUE v_self, VALUE v_parent)
{
  trace("cObject_parent_assign");
  track2("cObject_parent_assign(%s, %s)", v_self, v_parent);
  rb_check_frozen(v_self);
  QObject *parent = 0;
  if (!NIL_P(v_parent))
    {
      trace("retrieve QObject");
      GET_STRUCT_NODECL(QObject, parent);
    }
  trace("retrieve self");
  RQTDECLSELF(QObject);
  trace("Calling setParent");
  traqt2("%s::setParent(%s)", QTCLASS(self), QTCLASS(parent));
  self->setParent(parent);
  return v_parent;
}

static VALUE
cObject_alloc(VALUE cObject)
{
  trace("cObject_alloc");
  QObject * const object = new QObject;
  traqt1("new QObject -> %p", object);
  trace1("cApplication_alloc -> qptr %p", object);
  return cObjectWrap(cObject, object);
}

static VALUE
cObject_objectName_assign(VALUE v_self, VALUE vNewName)
{
  rb_check_frozen(v_self);
  RQTDECLSELF(QObject);
  traqt1("%s::setObjectName", QTCLASS(self));
  self->setObjectName(StringValueCStr(vNewName));
  return vNewName;
}

/* arg can be String or Hash or R::Qt::Object.
 * String sets name,
 * hash sets everything in it
 * cObject sets parent.
 *
 * Can be used without self being a QObject
 */
void
cObject_initialize_arg(VALUE v_self, VALUE v_arg)
{
  track2("cObject_initialize_arg(%s, %s)", v_self, v_arg);
  switch (TYPE(v_arg))
    {
    case T_STRING:
      rb_funcall(v_self, rb_intern("objectName="), 1, v_arg);
      //      cObject_objectName_assign(v_self, v_arg);	  this uses QObject.
      return;
    case T_HASH:
      rb_funcall(v_self, rb_intern("setupQuickyhash"), 1, v_arg);
      return;
    case T_DATA:
      if (rb_obj_is_kind_of(v_arg, cObject))
	{
	  rb_funcall(v_self, rb_intern("parent="), 1, v_arg);
	  return;
	}
      break;
    }
  rb_raise(rb_eTypeError, "BAD argtype %s for Object.new", rb_obj_classname(v_arg));
}

/** call-seq: new([parent = nil] [[,]name = nil] [[,]hash = nil] [[,] &block])
 *
*/
static VALUE
cObject_initialize(int argc, VALUE *argv, VALUE v_self)
{
  trace("cObject_initialize");
#if defined(DEBUG)
  QObject * const self = 
#endif
			 v2qt(v_self); // First mark ownership
#if defined(DEBUG)
  trace1("DEBUG: cObject_initialize(argc: %d), storing v_self in Property", argc);
  const VALUE vdbg = qt2v(self);
  trace1("DEBUG: vdbg=%p", (void *)vdbg);
  if (vdbg != v_self)
    rb_raise(rb_eFatal, "programming error qt2v <-> v2qt MISMATCH");
#endif
  //trace("scan args and assign parent");
  VALUE v_0, v_1, v_2;
  rb_scan_args(argc, argv, "03", &v_0, &v_1, &v_2);
  if (!NIL_P(v_0))
    {
      cObject_initialize_arg(v_self, v_0);
      if (!NIL_P(v_1))
	{
	  cObject_initialize_arg(v_self, v_1);
	  if (!NIL_P(v_2))
	    cObject_initialize_arg(v_self, v_2);
	}
    }
  if (rb_block_given_p())
    {
      rb_obj_instance_eval(0, 0, v_self);
    }
  trace("cObject_initialize OK");
  return Qnil;
}

static VALUE
cObject_objectName_get(VALUE v_self)
{
  RQTDECLSELF(QObject);
  return qString2v(self->objectName());
}

// Does not use QObject!
static VALUE
cObject_objectName(int argc, VALUE *argv, VALUE v_self)
{
  if (argc == 0) return rb_funcall(v_self, rb_intern("objectName_get"), 0);
  VALUE v_newname;
  rb_scan_args(argc, argv, "1", &v_newname);
  return rb_funcall(v_self, rb_intern("objectName="), 1, v_newname);
}

static VALUE
cObject_parent(int argc, VALUE *argv, VALUE v_self)
{
  trace("cObject_parent");
  RQTDECLSELF(QObject);
  if (argc == 0) 
    {
      traqt1("%s::parent", QTCLASS(self));
      return qt2v(self->parent());
    }
  VALUE v_new_parent;
  rb_scan_args(argc, argv, "1", &v_new_parent);
  return cObject_parent_assign(v_self, v_new_parent);
}

// Does not rely on QObject.
static VALUE
cObject_to_s(VALUE v_self)
{
  trace("cObject_to_s");
  // since to_s is used for debugging it is convenient if it accept zombies:
  if (IS_ZOMBIFIED(v_self)) return rb_str_new_cstr("zombie");
  // traqt1("%s::objectName", QTCLASS(self));
  VALUE v_objectName = rb_funcall(v_self, rb_intern("objectName"), 0);
  track1("objectName->%s", v_objectName);
  v_objectName = rb_funcall(v_objectName, rb_intern("to_s"), 0);
  track1("rb_any_to_s->%s", v_objectName);
  const char * const objectName = StringValueCStr(v_objectName);
  if (*objectName)
    {
      QString s;
      QTextStream t(&s);
      t << rb_obj_classname(v_self) << ":'" << objectName << "'";
      return qString2v(s);
    }
  return rb_call_super(0, 0);
}

/** :call-seq:
 *	children  
 *	children object-array
 *	children object1, object2, ...
 *
 * The first form returns an array (copy) of the children, possibly
 * empty.
 *
 * The second form assigns the given objects by removing the
 * parent of its own children, then setting the parent of 
 * the passed objects to self. 
 * IMPORTANT: the result can be orphans. If they are not a ruby object
 * they are currently NOT FREED causing MEMORY LEAKS!!!!
 * Apart from that, they may be Qt-internals (like QApplication has some)
 * and the system may crash!
 *
 * This behaviour may very well change.
 * In fact, the rw variant should be called 'children!' 
 */
static VALUE
cObject_children(int argc, VALUE *argv, VALUE v_self)
{
  trace2("%s::children, argc=%d", TO_S(v_self), argc);
  RQTDECLSELF(QObject);
  traqt1("%s::children", QTCLASS(self));
  const QObjectList &children = self->children();
  if (argc == 0)
    {
      const VALUE r = rb_ary_new2(children.count());
      foreach (QObject *child, children) // foreach is delete/remove-safe!
	{
	  const VALUE v_child = qt2v(child);
	  if (!NIL_P(v_child)) rb_ary_push(r, v_child);
	}
      return r;
    }
  rb_check_frozen(v_self);
  VALUE v_children;
  rb_scan_args(argc, argv, "*", &v_children);
  trace1("RARRAY_LEN=%ld", RARRAY_LEN(v_children));
  VALUE v_t = RARRAY_LEN(v_children) == 1 ? rb_check_array_type(rb_ary_entry(v_children, 0)) 
					  : Qnil;
  if (RTEST(v_t)) v_children = v_t;
  track1("v_children='%s'", v_children);
  trace1("assigning children, #oldchildren=%d", children.count());
  foreach (QObject *child, children)
    {
      trace1("setParent to 0 on child %p", child);
      traqt1("%s::setParent(0)", QTCLASS(child));
      child->setParent(0);
    }
  trace("rb_check_array_type");
  track1("v_children='%s'", v_children);
  const long N = RARRAY_LEN(v_children);
  trace1("N=%ld", N);
  long i = 0;
  for (VALUE *v_child = RARRAY_PTR(v_children); i < N; i++, v_child++)
    {
      if (!rb_obj_is_kind_of(*v_child, cObject))
	rb_raise(rb_eTypeError, "passed child %s that was not a QObject", TO_S(*v_child));
      trace2("i=%ld, N=%ld", i, N);
      GET_STRUCT_PTR(QObject, child);
      trace1("setParent to self on child %p", child);
      traqt2("%s::setParent(%s)", QTCLASS(child), QTCLASS(self));
      child->setParent(self);
    }
  return v_children;
} // cObject_children

/** iterate each direct child
 */
static VALUE
cObject_each_child(int argc, VALUE *argv, VALUE v_self)
{
  trace2("%s::each_child, argc=%d", TO_S(v_self), argc);
  RETURN_ENUMERATOR(v_self, argc, argv);
  RQTDECLSELF(QObject);
  traqt1("%s::children", QTCLASS(self));
  const QObjectList &children = self->children();
  foreach (QObject *child, children) // foreach is delete/remove-safe!
    {
      const VALUE v_child = qt2v(child);
      if (!NIL_P(v_child)) rb_yield(v_child);
    }
  return Qnil;
} // cObject_each_child

static VALUE
cObject_each_child_with_root(int argc, VALUE *argv, VALUE v_self)
{
  RETURN_ENUMERATOR(v_self, argc, argv);
  rb_yield(v_self);
  RQTDECLSELF(QObject);
  traqt1("%s::children", QTCLASS(self));
  foreach (QObject *child, self->children())
    {
      const VALUE v_child = qt2v(child);
      if (!NIL_P(v_child)) rb_yield(v_child);
    }
  return Qnil;
}

static void 
enqueue_children(VALUE v_object, VALUE v_queue, int &c)
{
  GET_STRUCT(QObject, object);
  traqt1("%s::children", QTCLASS(object));
  const QObjectList &children = object->children();
  foreach (QObject *child, children)
    {
      const VALUE v_child = qt2v(child);
      if (!NIL_P(v_child)) 
	{
	  rb_ary_push(v_queue, v_child);
	  ++c;
	}
    }
}

static VALUE
each_sub(VALUE v_self)
{
  VALUE v_queue = rb_ary_new();
  int c = 0;
  enqueue_children(v_self, v_queue, c); 
  while (c)
    {
      VALUE v_node = rb_ary_shift(v_queue);
      --c;
      rb_yield(v_node);
      enqueue_children(v_node, v_queue, c);
    }
  return Qnil;
}

/** breadth-first search, but it excludes SELF!!!
 */
static VALUE
cObject_each_sub(int argc, VALUE *argv, VALUE v_self)
{
  trace2("%s::each_sub, argc=%d", TO_S(v_self), argc);
  RETURN_ENUMERATOR(v_self, argc, argv);
  return each_sub(v_self);
} // cObject_each_sub

/** breadth-first search, and includes self (as first result)
 */
static VALUE
cObject_each_sub_with_root(int argc, VALUE *argv, VALUE v_self)
{
  RETURN_ENUMERATOR(v_self, argc, argv);
  rb_yield(v_self);
  return each_sub(v_self);
}

/** :call-seq:
 *	self connect(:symbol, proc)
 *	self connect(qt_signal_str, proc)
 *
 * The first one is ruby only.
 * The second one connects the Qt signal and is C only.
 * the '2' prefix must be removed, so it looks like:  
 *	obj.connect('destroyed(QObject *)', proc)
 */
static VALUE 
cObject_connect(VALUE v_self, VALUE v_signal, VALUE v_proc)
{
  trace("cObject_connect");
  rb_check_frozen(v_self);
  track3("cObject_connect %s, %s, %s", v_self, v_signal, v_proc);
  if (TYPE(v_signal) == T_SYMBOL)
    {
      // ((@connections ||= {})[symbol] ||= []) << block
      VALUE v_connections;
      if (TYPE(v_connections = rb_iv_get(v_self, "@connections")) != T_HASH)
	{
	  rb_iv_set(v_self, "@connections", v_connections = rb_hash_new());
	}
      VALUE v_proxylist = rb_hash_aref(v_connections, v_signal);
      if (TYPE(v_proxylist) != T_ARRAY)
	{
	  rb_hash_aset(v_connections, v_signal, v_proxylist = rb_ary_new());
	}
      rb_ary_push(v_proxylist, v_proc);
      return Qnil;
    }
  RQTDECLSELF(QObject);
  const char * const signal = StringValueCStr(v_signal);
  trace1("native Qt signal '%s'", signal);
  new QSignalProxy(self, signal, v_proc); 
  return v_self;
}

/* WARNING: in case of emit v_args is extended!! 
 * */
VALUE 
cObject_signal_implementation(VALUE v_self, VALUE v_method, 
			      VALUE v_signal, VALUE v_args, VALUE v_block)
{
  track1("cObject_signal_implementation for method %s", v_method);
  if (TYPE(v_method) != T_SYMBOL) 
    rb_raise(rb_eTypeError, "method is not a symbol");
  v_args = to_ary(v_args); // PARANOIA
  const long N = RARRAY_LEN(v_args);
  if (!NIL_P(v_block))
    {
      trace("block given call 'connect'");
      if (N) rb_raise(rb_eTypeError, "cannot use args with block");
      // AARGHHHH      const VALUE v_connect = RQT2SYM(connect);
      trace("rb_funcall");
      //rb_raise(rb_eRuntimeError, "err...."); // SEGV ?
      rb_funcall(v_self, rb_intern("connect"), 2, v_signal, v_block);
      trace("connected");
    }
  else
    {
      /* NOT REQUIRED
      VALUE v_new_ary = rb_ary_new2(RARRAY_LEN(v_args) + 1);
      rb_ary_push(v_new_ary, v_method);
      int i = 0;
      for (VALUE *v_el = RARRAY_PTR(v_args); i < N; i++, v_el++)
	rb_ary_push(v_new_ary, *v_el);
      // SEGV ??
       */
      rb_ary_unshift(v_args, v_method);
      trace2("rb_funcall2 -> emit(%s), #args=%ld", INSPECT(v_method),
	     RARRAY_LEN(v_args));
      rb_funcall2(v_self, rb_intern("emit"), RARRAY_LEN(v_args), RARRAY_PTR(v_args));
    }
  return v_self;
}

/** :call-seq:
 *	self emit(:symbol, *args, &proc)
 *	self emit(qt_signal_str, *args, &proc)
 */
static VALUE
cObject_emit(int argc, VALUE *argv, VALUE v_self)
{
  trace1("%s::emit", TO_S(v_self));
  VALUE v_symbol, v_args; //, v_proc;
  rb_scan_args(argc, argv, "1*", &v_symbol, &v_args); //, &v_proc);
  if (rb_block_given_p()) rb_raise(rb_eTypeError, "blocks cannnot be passed to emit");
  track1("symbol=%s", v_symbol);
  if (TYPE(v_symbol) == T_SYMBOL)
    {
      track1("Ruby sender through %s", v_symbol);
      /*
	  @connections and
	    connections = @connections[symbol] and
	      for proxy in connections
		proxy[*args, &block]
	      end
      */
      const VALUE v_connections = rb_iv_get(v_self, "@connections");
      track1("connections = %s", v_connections);
      if (TYPE(v_connections) == T_HASH)
	{
	  const VALUE v_proxylist = rb_hash_aref(v_connections, v_symbol);
	  track1("proxylist = %s", v_proxylist);
	  if (TYPE(v_proxylist) == T_ARRAY)
	    {
	      const long N = RARRAY_LEN(v_proxylist);
	      trace1("located %ld connections", N);
	      long i = 0;
	      /*
	      const bool has_block = !NIL_P(v_proc);
	      if (has_block)
		{
		  argc = RARRAY_LEN(v_args);
		  argv = RARRAY_PTR(v_args);
		}
		*/
	      for (VALUE *v_proxy = RARRAY_PTR(v_proxylist); i < N; i++, v_proxy++)
		{
		  /*
		  if (has_block)
		    rb_proc_call_with_block(*v_proxy, argc, argv, v_proc);
		  else 
		  */
		  track2("rb_proc_call proxy %s with args=%s", *v_proxy, v_args);
		  rb_proc_call(*v_proxy, v_args);
		}
	    }
	}
      else
	{
	  trace("NO CONNECTIONS");
	}
      return v_self;
    }
  else
      rb_raise(rb_eNotImpError, "emitting qt-signals...");
}

static VALUE
cObject_widget_p(VALUE v_self)
{
  RQTDECLSELF(QObject);
  traqt1("%s::isWidgetType", QTCLASS(self));
  trace1("cObject_widget_p, isWidgetType -> %d", self->isWidgetType());
  return p(self->isWidgetType());
}

static VALUE
init_object()
{
  trace("init_object");
  rb_define_alloc_func(cObject, cObject_alloc);
  rb_define_method(cObject, "initialize", RUBY_METHOD_FUNC(cObject_initialize), -1);
  rb_define_method(cObject, "parent", RUBY_METHOD_FUNC(cObject_parent), -1);
  rb_define_method(cObject, "parent=", RUBY_METHOD_FUNC(cObject_parent_assign), 1);
  rb_define_method(cObject, "children", RUBY_METHOD_FUNC(cObject_children), -1);
  rb_define_method(cObject, "objectName", RUBY_METHOD_FUNC(cObject_objectName), -1);
  // _get is required for Control::dynamic_attr.
  rb_define_method(cObject, "objectName_get", RUBY_METHOD_FUNC(cObject_objectName_get), 0);
  rb_define_method(cObject, "objectName=", RUBY_METHOD_FUNC(cObject_objectName_assign), 1);
  rb_define_method(cObject, "delete", RUBY_METHOD_FUNC(cObject_delete), 0);
  rb_define_method(cObject, "zombified?", RUBY_METHOD_FUNC(cObject_zombified_p), 0);
  rb_define_method(cObject, "widget?", RUBY_METHOD_FUNC(cObject_widget_p), 0);
//  rb_define_method(cObject, "findChild", RUBY_METHOD_FUNC(cObject_findChild), -1);
  rb_define_method(cObject, "each_child", RUBY_METHOD_FUNC(cObject_each_child), -1);
  rb_define_method(cObject, "each", RUBY_METHOD_FUNC(cObject_each_child), -1);
  rb_define_method(cObject, "each_sub", RUBY_METHOD_FUNC(cObject_each_sub), -1);
  rb_define_method(cObject, "each_sub_with_root", 
		   RUBY_METHOD_FUNC(cObject_each_sub_with_root), -1);
  rb_define_method(cObject, "each_child_with_root", 
		   RUBY_METHOD_FUNC(cObject_each_child_with_root), -1);
  rb_define_private_method(cObject, "connect", RUBY_METHOD_FUNC(cObject_connect), 2);
  rb_define_private_method(cObject, "emit", RUBY_METHOD_FUNC(cObject_emit), -1);
  rb_define_private_method(cObject, "signal_implementation", 
			   RUBY_METHOD_FUNC(cObject_signal_implementation), 4);
  rb_define_method(cObject, "to_s", RUBY_METHOD_FUNC(cObject_to_s), 0);
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
  VALUE vSource, vDisambiguation, vCount;
  rb_scan_args(argc, argv, "12", &vSource, &vDisambiguation, &vCount);
  track3("mReform_tr(%s, %s, %s)", vSource, vDisambiguation, vCount);
  VALUE t = rb_check_string_type(vCount);
  if (!NIL_P(t))
    {
      vCount = vDisambiguation;
      vDisambiguation = t;
    }
#define IGNORE_THIS_TR trUtf8
  return qString2v(QObject::IGNORE_THIS_TR(StringValueCStr(vSource), 
					   NIL_P(vDisambiguation) 
					   ? 0 : StringValueCStr(vDisambiguation), 
					   NIL_P(vCount) ? -1 : NUM2INT(vCount)));
}

static inline void
init_qt()
{
  trace("init_qt");
  mR = rb_define_module("R");
  mQt = rb_define_module_under(mR, "Qt");
  cObject = rb_define_class_under(mQt, "Object", rb_cObject);
}

} // namespace R_Qt 

using namespace R_Qt;

void
Init_liburqtCore()
{
  static bool loaded = false;
  trace1("Init_liburqtCore, loaded=%d", loaded);
  if (loaded) return;
  init_qt();
  const VALUE mReform = rb_define_module_under(mR, "EForm");
  rb_define_module_function(mReform, "tr", RUBY_METHOD_FUNC(mReform_tr), -1);
  init_rvalue(); // assigns RVALUE_ID
  init_object();
  loaded = true;
  trace("Init_liburqtCore OK");
}
