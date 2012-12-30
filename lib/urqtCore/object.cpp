
//#define TRACE

#pragma implementation
#include <ruby.h>
#include "api_utils.h"
#include "object.h"
#include <QtCore/QTextStream>

namespace R_Qt {

VALUE 
mQt = Qnil, cObject = Qnil;

static inline void
ZOMBIFY(VALUE v)
{
  DATA_PTR(v) = 0;
}

static inline bool
IS_ZOMBIFIED(VALUE v)
{
  return DATA_PTR(v) == 0;
}

/* delete of object will also delete all subs.
 * So any ruby reference into it must die!
 */
static void
zombify(QObject *object)
{
  const VALUE v_object = qt2v(object);
  trace1("HERE, v_object=%p", (void *)v_object);
  track1("ITER: got v_object %s", v_object);
  if (!NIL_P(v_object))
    {
      trace("zombify child");
      ZOMBIFY(v_object);
    }
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
 */

void 
cObject_delete(VALUE v_self)
{
  if (IS_ZOMBIFIED(v_self)) return;
  GET_STRUCT(QObject, self);
  trace4("cObject_free(qptr=%p, class=%s, name='%s', #children=%d)", self, 
	 self->metaObject()->className(), qString2cstr(self->objectName()),
	 self->children().count());
  track1("Freeing ruby VALUE %s", v_self);
  zombify(self);
  delete self;
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
  trace3("cObject_mark(qptr=%p, class=%s, #children=%d)", object, 
	 object->metaObject()->className(), object->children().count());
  foreach (QObject *child, object->children())
    {
      const VALUE vChild = qt2v(child);
      if (!NIL_P(vChild))
	rb_gc_mark(vChild);
    }
  foreach (const QByteArray &propname, object->dynamicPropertyNames())
    {
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
  track2("cObject_parent_assign(%s, %s)", v_self, v_parent);
  QObject *parent = 0;
  if (!NIL_P(v_parent))
    {
      GET_STRUCT_NODECL(QObject, parent);
      if (!rb_obj_is_instance_of(v_parent, cObject))
	rb_bug("Tried to set parent to non-QObject");
    }
  GET_STRUCT(QObject, self);
  trace("Calling setParent");
  self->setParent(parent);
  return v_parent;
}

static VALUE
cObject_alloc(VALUE cObject)
{
  trace("cObject_alloc");
  QObject * const object = new QObject;
  trace1("cApplication_alloc -> qptr %p", object);
  return cObjectWrap(cObject, object);
}

static VALUE
cObject_objectName_assign(VALUE v_self, VALUE vNewName)
{
  GET_STRUCT(QObject, self);
  self->setObjectName(StringValueCStr(vNewName));
  return vNewName;
}

/* arg can be String or Hash or R::Qt::Object.
 * String sets name,
 * hash sets everything in it
 * cObject sets parent.
 */
static void
cObject_initialize_arg(VALUE v_self, VALUE v_arg)
{
  track2("cObject_initialize_arg(%s, %s)", v_self, v_arg);
  switch (TYPE(v_arg))
    {
    case T_STRING:
      cObject_objectName_assign(v_self, v_arg);
      return;
    case T_HASH:
      rb_funcall(v_self, rb_intern("setupQuickyhash"), 1, v_arg);
      return;
    case T_DATA:
      if (rb_obj_is_instance_of(v_arg, cObject))
	{
	  cObject_parent_assign(v_self, v_arg);
	  return;
	}
    }
  rb_bug("BAD argtype %s for Object.new", rb_obj_classname(v_arg));
}

/** call-seq: new([parent = nil] [[,]name = nil] [[,]hash = nil] [[,] &block])
 *
*/
static VALUE
cObject_initialize(int argc, VALUE *argv, VALUE v_self)
{
  trace("cObject_initialize HERE");
#if defined(DEBUG)
  QObject * const self = 
#endif
			 v2qt(v_self); // First mark ownership
  trace("cObject_initialize HERE2");
#if defined(DEBUG)
  trace1("DEBUG: cObject_initialize(argc: %d), storing v_self in Property", argc);
  const VALUE vdbg = qt2v(self);
  trace1("DEBUG: vdbg=%p", (void *)vdbg);
  if (vdbg != v_self)
    rb_bug("programming error qt2v <-> v2qt MISMATCH");
#endif
  trace("scan args and assign parent");
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
cObject_objectName(int argc, VALUE *argv, VALUE v_self)
{
  GET_STRUCT(QObject, self);
  if (argc == 0) return qString2v(self->objectName());
  VALUE vNewName;
  rb_scan_args(argc, argv, "1", &vNewName);
  return cObject_objectName_assign(v_self, vNewName);
}

static VALUE
cObject_parent(int argc, VALUE *argv, VALUE v_self)
{
  GET_STRUCT(QObject, self);
  if (argc == 0) return qt2v(self->parent());
  VALUE v_new_parent;
  rb_scan_args(argc, argv, "1", &v_new_parent);
  cObject_parent_assign(v_self, v_new_parent);
  GET_STRUCT(QObject, new_parent);
  self->setParent(new_parent);
  return v_new_parent;
}

static VALUE
cObject_to_s(VALUE v_self)
{
  trace("cObject_to_s");
  // since to_s is used for debugging it is convenient if it accept zombies:
  if (IS_ZOMBIFIED(v_self)) return rb_str_new_cstr("zombie");
  GET_STRUCT(QObject, self);
  trace1("self=%p", self);
  const QString &objectName = self->objectName();
  if (!objectName.isEmpty())
    {
      QString s;
      QTextStream t(&s);
      t << rb_obj_classname(v_self) << ":" << objectName;
      return qString2v(s);
    }
  return rb_call_super(0, 0);
}

/** :call-seq: 
 *     connect(sender, signal, receiver, slot)
 *     connect(signal, receiver, slot)
 *     connect(signal, receiver, &slot)
 *     connect(sender, signal, slot)
 *     connect(signal, &slot).
 *
 *  Note that SIGNAL() and SLOT() are applied on the strings 'signal'
 *  and 'slot'.
 *
 *  If a block is used with a receiver it is executed in its context.
 *  Otherwise the original context is used.
 *  If the receiver is not set 'self' is the receiver.
 *  If the sender is not set 'self' is the sender.
 *  Signals and slots that are C++ functiontypes evade ruby. 
static VALUE
cObject_connect(int argc, VALUE *argv, VALUE v_self)
{
  GET_STRUCT(QObject, self);
  rb_raise(rb_eNotImpError, "cObject_connect");
}
 */

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
 * This behaviour may very well change.
 */
static VALUE
cObject_children(int argc, VALUE *argv, VALUE v_self)
{
  trace2("%s::children, argc=%d", TO_S(v_self), argc);
  GET_STRUCT(QObject, self);
  const QObjectList &children = self->children();
  if (argc == 0)
    {
      const VALUE r = rb_ary_new2(children.count());
      foreach (QObject *child, children) // foreach is delete/remove-safe!
	rb_ary_push(r, qt2v(child));
      return r;
    }
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
      child->setParent(0);
    }
  trace("rb_check_array_type");
  track1("v_children='%s'", v_children);
  const long N = RARRAY_LEN(v_children);
  trace1("N=%ld", N);
  long i = 0;
  for (VALUE *v_child = RARRAY_PTR(v_children); i < N; i++, v_child++)
    {
      if (!rb_obj_is_instance_of(*v_child, cObject))
	rb_bug("passed child %s that was not a QObject", TO_S(*v_child));
      trace2("i=%ld, N=%ld", i, N);
      GET_STRUCT_PTR(QObject, child);
      trace1("setParent to self on child %p", child);
      child->setParent(self);
    }
  return v_children;
} // cObject_children

static VALUE
init_object(VALUE mQt)
{
  cObject = rb_define_class_under(mQt, "Object", rb_cObject);
  rb_define_alloc_func(cObject, cObject_alloc);
  rb_define_method(cObject, "initialize", RUBY_METHOD_FUNC(cObject_initialize), -1);
  rb_define_method(cObject, "parent", RUBY_METHOD_FUNC(cObject_parent), -1);
  rb_define_method(cObject, "children", RUBY_METHOD_FUNC(cObject_children), -1);
  rb_define_method(cObject, "parent=", RUBY_METHOD_FUNC(cObject_parent_assign), 1);
  rb_define_method(cObject, "objectName", RUBY_METHOD_FUNC(cObject_objectName), -1);
  rb_define_method(cObject, "objectName=", RUBY_METHOD_FUNC(cObject_objectName_assign), 1);
//  rb_define_method(cObject, "connect", RUBY_METHOD_FUNC(cObject_connect), -1);
  rb_define_method(cObject, "delete", RUBY_METHOD_FUNC(cObject_delete), 0);
  rb_define_method(cObject, "to_s", RUBY_METHOD_FUNC(cObject_to_s), 0);
  return cObject;
}

/*  STUPID IDEA
 *
 *  HOWEVER....
 *  the current zombie system is NOT SAFE...
 *
 *  For example, if a Widget is zombified it changes from a QWidget
 *  to a QZombie...
 *  And Data_Get_Struct would perform an illegal cast (on v_self).
 *  
 *  We may change this to an rb_raise through GET_STRUCT.
 *  But in that case we can zombify also by storing 0 in the struct.
 *
static VALUE
v_zombie;

static VALUE
cZombie_alloc(VALUE cZombie)
{
  const VALUE v_zombie = cObjectWrap(cZombie, new QZombie);
  rb_gc_register_address(v_zombie);
  return v_zombie;
}

static VALUE
cZombie_delete(VALUE v_self)
{
}

static VALUE
init_zombie(VALUE mQt)
{
  cZombie = rb_define_class_under(mQt, "Zombie", cObject);
  rb_define_alloc_func(cZombie, cZombie_alloc);
  v_zombie = rb_class_allocate_instance(0, 0, cZombie); 
  rb_define_method(cZombie, "delete", RUBY_METHOD_FUNC(cZombie_delete), 0);
}
*/

/** :call-seq: tr(source, [disambiguation = '',] count = -1)
 *
 * Note that the encoding must be utf-8
 */
static VALUE
mReform_tr(int argc, VALUE *argv, VALUE /*v_self*/)
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

} // namespace R_Qt 

using namespace R_Qt;

extern "C" void
Init_liburqtCore()
{
  const VALUE mR = rb_define_module("R"); 
  mQt = rb_define_module_under(mR, "Qt");
  const VALUE mReform = rb_define_module_under(mR, "EForm");
  rb_define_module_function(mReform, "tr", RUBY_METHOD_FUNC(mReform_tr), -1);
  init_rvalue(); // assigns RVALUE_ID
  init_object(mQt);
  //init_zombie(mQt);
}
