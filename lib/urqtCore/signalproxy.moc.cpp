
//#define TRACE

#pragma implementation

#include "signalproxy.moc.h"
#include "object.h"
#include <QtCore/QMetaMethod>

namespace R_Qt {

QSignalProxy::QSignalProxy(QObject *parent, const char *signal, VALUE v_block):
inherited(parent),
Block(v_block)
{
  if (!parent) rb_raise(rb_eTypeError, "Bad parent");
  traqt("QMetaObject::normalizedSignature");
  QByteArray qsig = QMetaObject::normalizedSignature(signal);
  traqt1("%s::metaObject", QTCLASS(parent));
  const QMetaObject &meta_parent = *parent->metaObject();
  signal = qsig.data();
  const char * const brop = strchr(signal, '(');
  if (!brop) rb_raise(rb_eTypeError, "Bad signal '%s'", signal);
  const int i_parent_signal = meta_parent.indexOfSignal(signal);
  if (i_parent_signal == -1)
    rb_raise(rb_eRuntimeError, "Signal '%s' not found in parent", signal);
  trace1("call QObject::connect signal '%s' creating QMetaObject::Connection", signal);
  // locate the correct 'handle' 
  QByteArray qslot;
  qslot.append("handle");
  qslot.append(brop);
  traqt("QSignalProxy::metaObject");
  const QMetaObject &meta = *QSignalProxy::metaObject();
  traqt("QMetaObject::indexOfSlot");
  const int i_slot = meta.indexOfSlot(qslot);
  if (i_slot == -1)
    rb_raise(rb_eRuntimeError, "no broker available for signal %s", signal);
  traqt("QMetaObject::method");
  QMetaMethod method_parent = meta_parent.method(i_parent_signal);
  traqt("QMetaObject::method");
  QMetaMethod method = meta.method(i_slot);
  trace("slot located");
  traqt1("%s::connect", QTCLASS(this));
  const QMetaObject::Connection c = connect(parent, method_parent, this, method);
  if (!c)
    rb_raise(rb_eRuntimeError, "invalid connection on signal %s", signal);
}

static VALUE 
sp_handle_callback(VALUE /*v_yielded*/, VALUE v_arg)
{
  track2("sp_handle_callback(yielded: %s, %s)", v_yielded, v_arg);
  // v_arg is always an Array
  VALUE block = rb_ary_entry(v_arg, 0);
  VALUE v_ary = rb_ary_entry(v_arg, 1);
  track2("rb_proc_call(%s, %s)", block, v_ary);
  return rb_proc_call(block, v_ary);
}

void 
QSignalProxy::handle_i(VALUE v_ary) const
{
  track2("handle_i(%s) on block %s", v_ary, block());
  if (!rb_obj_is_proc(block())
      || TYPE(v_ary) != T_ARRAY)
    rb_raise(rb_eTypeError, "QSignalProxy CORRUPTION DETECTED");
  //rb_proc_call(Block, v_ary);	  works as good as below, ie  both SEGV!!! when tried twice.
  //
  //	R::escue do
  //	  Block[v_ary]
  //	end
  //
  VALUE val = rb_ary_new3(2, block(), v_ary);
  rb_block_call(mR, rb_intern("escue"), 0, 0, RUBY_METHOD_FUNC(sp_handle_callback), val);
  //BROKEN rb_iterate(sp_handle_rescue, mR, RUBY_METHOD_FUNC(sp_handle_callback), val);
}

void 
QSignalProxy::handle() const
{
  handle_i(rb_ary_new());
}

void 
QSignalProxy::handle(QObject *object) const
{
  VALUE v_object = qt2v(object);
  handle_i(rb_ary_new3(1, v_object));
}

void 
QSignalProxy::handle(bool value) const
{
  handle_i(rb_ary_new3(1, p(value)));
}

} // namespace R_Qt
