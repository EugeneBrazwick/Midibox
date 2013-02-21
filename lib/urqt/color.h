#if !defined(_URQT_COLOR_H_)
#define _URQT_COLOR_H_

// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

#include <QtGui/QColor>
#include "api_utils.h"
#include "ruby++/ruby++.h"

#pragma interface

namespace R_Qt {

extern RPP::Class cColor, cDynamicColor;

static inline void
GetQColor_noDecl(VALUE v_q, QColor *&q)
{
#if defined(DEBUG)
  if (!rb_obj_is_kind_of(v_q, cColor))
    rb_raise(rb_eTypeError, "SERIOUS PROGRAMMING ERROR: very bad cast to QColor");
#endif // DEBUG
  GET_STRUCT_NODECL(QColor, q);
}

#define RQTDECLARE_COLOR(var) QColor *var; GetQColor_noDecl(v_##var, var)

extern void cColor_free(QColor *color);

static inline VALUE
cColorWrap(QColor *color)
{
  trace1("cColorWrap(%p)", color);
  return Data_Wrap_Struct(cColor, 0, cColor_free, color);
} // cColorWrap

static inline VALUE
cColorWrap(const QColor &color)
{
  return Data_Wrap_Struct(cColor, 0, cColor_free, new QColor(color));
} // cColorWrap

extern void init_color(RPP::Module qt);

} // namespace R_Qt 

namespace RPP {

class QColor: public DataObject< ::QColor >
{
private:
  typedef DataObject< ::QColor > inherited;
public:
  QColor(VALUE v_o): inherited(v_o, R_Qt::cColor) {}
  QColor(::QColor *color): inherited(Data_Wrap_Struct(R_Qt::cColor, 0, R_Qt::cColor_free, color), color) {}
  QColor(const ::QColor &color): QColor(new ::QColor(color)) {}
  /*
    inherited(Data_Wrap_Struct(R_Qt::cColor, 0, R_Qt::cColor_free, new ::QColor(color)), ???)
    {
    }
    */
}; // class RPP::QColor


} // namespace RPP 
#endif // _URQT_COLOR_H_
