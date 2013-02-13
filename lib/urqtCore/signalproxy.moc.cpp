
//#define TRACE

#pragma implementation

#include "signalproxy.moc.h"
#include "object.h"
#include "ruby++/proc.h"
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
    rb_raise(rb_eRuntimeError, "no broker available for signal %s\n"
			       "Please fix urqtCore/signalproxy.moc.cpp", 
	     signal);
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
  // v_arg is ALWAYS an Array
  const RPP::Array arg(v_arg, RPP::Array::Unsafe);
  const RPP::Proc block = arg[0];
  const RPP::Array arg1 = arg[1];
  track2("rb_proc_call(%s, %s)", block, arg1);
  return block.callback(arg1);
}

void 
QSignalProxy::handle_i(RPP::Array v_ary) const
{
  track2("handle_i(%s) on block %s", v_ary, block());
  mR.call_with_block("escue", sp_handle_callback, block(), v_ary);
}

void 
QSignalProxy::handle() const
{
  handle_i(RPP::Array());
}

void 
QSignalProxy::handle(QObject *object) const
{
  //  VERY BAD IDEA.  since VALUE -> array tries to convert it. handle_i(qt2v(object));
  handle_i(RPP::Array(qt2v(object), RPP::Array::CreateSingleton)); 
}

void 
QSignalProxy::handle(bool value) const
{
  handle_i(value);
}

void 
QSignalProxy::handle(int value) const
{
  // This might go:	int -> VALUE -> Array(VALUE)
  // But it should do:	int -> Array(int)
  // Fortunately VALUE is not a macro but a typedef
  handle_i(value);
}

} // namespace R_Qt
