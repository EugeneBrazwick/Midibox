#if !defined(_URQT_BRUSH_H_)
#define _URQT_BRUSH_H_

// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

#include <QtWidgets/QGraphicsItem>
#include <ruby/ruby.h>
#include "api_utils.h"

#pragma interface

namespace R_Qt {

extern VALUE cBrush, cColor;

static inline void
GetQBrush_noDecl(VALUE v_q, QBrush *&q)
{
#if defined(DEBUG)
  if (!rb_obj_is_kind_of(v_q, cBrush))
    rb_raise(rb_eTypeError, "SERIOUS PROGRAMMING ERROR: very bad cast to QBrush");
#endif // DEBUG
  GET_STRUCT_NODECL(QBrush, q);
}

static inline void
GetQColor_noDecl(VALUE v_q, QColor *&q)
{
#if defined(DEBUG)
  if (!rb_obj_is_kind_of(v_q, cColor))
    rb_raise(rb_eTypeError, "SERIOUS PROGRAMMING ERROR: very bad cast to QColor");
#endif // DEBUG
  GET_STRUCT_NODECL(QColor, q);
}

#define RQTDECLARE_BRUSH(var) QBrush *var; GetQBrush_noDecl(v_##var, var)
#define RQTDECLARE_COLOR(var) QColor *var; GetQColor_noDecl(v_##var, var)

extern void cBrush_free(QBrush *brush);

static inline VALUE
cBrushWrap(QBrush *brush)
{
  return Data_Wrap_Struct(cBrush, 0, cBrush_free, brush);
}

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

extern void init_color(VALUE mQt);
extern void init_brush(VALUE mQt);

} // namespace R_Qt 
#endif // _URQT_BRUSH_H_
