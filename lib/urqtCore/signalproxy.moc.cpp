
//#define TRACE

#pragma implementation

#include "signalproxy.moc.h"
#include "api_utils.h"
#include <QtCore/QMetaMethod>

namespace R_Qt {

QSignalProxy::QSignalProxy(QObject *parent, const char *signal, VALUE v_block):
inherited(parent),
Block(v_block)
{
  QByteArray qsig = QMetaObject::normalizedSignature(signal);
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
  const QMetaObject &meta = *QSignalProxy::metaObject();
  const int i_slot = meta.indexOfSlot(qslot);
  if (i_slot == -1)
    rb_raise(rb_eRuntimeError, "no broker available for signal %s", signal);
  QMetaMethod method_parent = meta_parent.method(i_parent_signal);
  QMetaMethod method = meta.method(i_slot);
  trace("slot located");
  const QMetaObject::Connection c = connect(parent, method_parent, this, method);
  if (!c)
    rb_raise(rb_eRuntimeError, "invalid connection on signal %s", signal);
}

void 
QSignalProxy::handle(QObject *object) const
{
  VALUE v_object = qt2v(object);
  rb_proc_call(Block, rb_ary_new3(1, v_object));
}

} // namespace R_Qt
