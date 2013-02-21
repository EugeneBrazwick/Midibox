#if !defined(_URQT_BRUSH_H_)
#define _URQT_BRUSH_H_

// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

#include <QtWidgets/QGraphicsItem>
#include <QtGui/QBrush>
#include "api_utils.h"
#include "ruby++/ruby++.h"

#pragma interface

namespace R_Qt {

extern RPP::Class cBrush;

static inline void
GetQBrush_noDecl(VALUE v_q, QBrush *&q)
{
#if defined(DEBUG)
  if (!rb_obj_is_kind_of(v_q, cBrush))
    rb_raise(rb_eTypeError, "SERIOUS PROGRAMMING ERROR: very bad cast from %s to QBrush",
	     INSPECT(v_q));
#endif // DEBUG
  GET_STRUCT_NODECL(QBrush, q);
}

#define RQTDECLARE_BRUSH(var) QBrush *var; GetQBrush_noDecl(v_##var, var)

extern void cBrush_free(QBrush *brush);

static inline VALUE
cBrushWrap(QBrush *brush)
{
  return Data_Wrap_Struct(cBrush, 0, cBrush_free, brush);
}

extern void init_brush(VALUE mQt);

} // namespace R_Qt 

namespace RPP {
class QBrush: public DataObject< ::QBrush >
{
private:
  typedef DataObject< ::QBrush > inherited;
public:
  /* If Unsafe is passed then the result can be nil as well as a QBrush.
     But exceptions are raised if it is neither.
     The caller MUST test for isNil()!
   */
  QBrush(VALUE v_o, E_SAFETY safe = SAFE): inherited(v_o, R_Qt::cBrush, safe) {}
  QBrush(::QBrush *brush): inherited(Data_Wrap_Struct(R_Qt::cBrush, 0, R_Qt::cBrush_free, brush), brush) {}
  QBrush(const ::QBrush &brush): QBrush(new ::QBrush(brush)) {}
  void operator=(VALUE v) { V = v; }
  // CRAZY  void operator=(const RPP::QBrush &other) { V = other.value(); }
}; // class RPP::QBrush

} // namespace RPP 
#endif // _URQT_BRUSH_H_
