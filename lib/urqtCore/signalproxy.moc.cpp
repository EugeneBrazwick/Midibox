
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

//#define TRACE

#pragma implementation

#include "signalproxy.moc.h"
#include "animation.h"
#include "ruby++/proc.h"
#include <QtCore/QMetaMethod>

namespace R_Qt {

/* the idea is as follows:
 *
 * We delegate to
 *    connect(parent, method_parent, signalproxy, method);
 *
 * where
 *    'method_parent' is the method 'signal' in 'parent'
 * and
 *    'method' is the 'handle' method in signalproxy itself
 *
 * So if parent.signal is 'emitted' we call signalproxy.handle() with the same signature 
 * as the original signal.
 * And we then arrive in QSignalProxy.handle_i which calls v_block with the arguments
 * from the signal.
 *
 * QSignalProxy is a QObject and it becomes a child of 'parent'.
 *
 * Context:   Qt::Object.connect(signalstring, rubyproc)
 * Not used at all if signal was a symbol!
 *
 */
QSignalProxy::QSignalProxy(QObject *parent, const char *signalname, VALUE v_block):
inherited(parent),
Block(v_block),
QSig(QMetaObject::normalizedSignature(signalname)),
Signal(QSig.data())
{
  if (!parent) rb_raise(rb_eTypeError, "Bad parent");
  trace2("new QSignalProxy for %s::%s", parent->metaObject()->className(), signalname);
  trace2("this->%p, block = %s", this, INSPECT(v_block));
  const QMetaObject &meta_parent = *parent->metaObject();
  const char * const brop = strchr(Signal, '(');
  if (!brop) rb_raise(rb_eTypeError, "Bad signal '%s'", Signal);
  const int i_parent_signal = meta_parent.indexOfSignal(Signal);
  if (i_parent_signal == -1)
    rb_raise(rb_eRuntimeError, "Signal '%s' not found in parent", Signal);
  trace1("call QObject::connect signal '%s' creating QMetaObject::Connection", Signal);
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
	     Signal);
  QMetaMethod method_parent = meta_parent.method(i_parent_signal);
  traqt("QMetaObject::method");
  QMetaMethod method = meta.method(i_slot);
  trace1("slot for signal %s located", Signal);
  traqt1("%s::connect", QTCLASS(this));
  const QMetaObject::Connection c = connect(parent, method_parent, this, method);
  if (!c)
    rb_raise(rb_eRuntimeError, "invalid connection on signal %s", Signal);
}

static VALUE 
sp_handle_callback(VALUE /*v_yielded*/, VALUE v_arg)
{
  track1("sp_handle_callback() arg=%s", v_arg);
  // v_arg is ALWAYS an Array in our case
  const RPP::Array arg(v_arg, RPP::VERYUNSAFE);
  const RPP::Proc block = arg[0];
  const RPP::Array arg1 = arg[1];
  track2("rb_proc_call(%s, %s)", block, arg1);
  return block.callback(arg1);
}

void 
QSignalProxy::handle_i(RPP::Array v_ary) const
{
  // SEGV ?trace3("SIGNAL[%s].handle_i(%s) on block %s", Signal, v_ary.inspect(), INSPECT(block()));
  track1("v_ary = %s", v_ary);
  trace2("this=%p, Signal = '%s'", this, Signal);
  track1("block = %s", block()); // SEGV
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
  trace2("SIGNAL[%s].handle(int: %d)", Signal, value);
  handle_i(RPP::Array(value, RPP::Array::CreateSingleton));
}

void 
QSignalProxy::handle(QAbstractAnimation::State old, QAbstractAnimation::State newstate) const
{
  trace3("SIGNAL[%s].handle(QAbstractAnimation::State: %d, "
         "QAbstractAnimation::State: %d)", Signal, old, newstate);
  const RPP::Array ary(QAbstractAnimation_State2Symbol(old), 
		       QAbstractAnimation_State2Symbol(newstate));
  track1("ary=%s", ary);
  handle_i(ary);
}

} // namespace R_Qt
