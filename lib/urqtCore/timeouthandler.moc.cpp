
// This document adheres to the GNU coding standard
//#define TRACE

#pragma implementation

#include "timeouthandler.moc.h"
#include "ruby++/proc.h"

namespace R_Qt {

QTimeoutHandler::QTimeoutHandler(VALUE v_block, EShot singleshot, QObject *parent):
inherited(parent),
SingleShot(singleshot == Single),
Block(v_block)
{
}

void
QTimeoutHandler::handle() //   const	clashes with deleteLater()
{
  RPP::Proc(Block).callback();
  if (SingleShot) deleteLater();
}

} // namespace R_Qt 
