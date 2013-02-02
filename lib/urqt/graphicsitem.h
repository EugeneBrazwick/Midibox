#if !defined(_URQT_GRAPHICSITEM_H_)
#define _URQT_GRAPHICSITEM_H_

// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

#include <QtWidgets/QGraphicsItem>
#include <ruby/ruby.h>
#include "api_utils.h"

#pragma interface

namespace R_Qt {

extern void cGraphicsItem_mark(QGraphicsItem *item);

// used for R_QT_DEF_GRALLOCATOR:
static inline VALUE 
cGraphicsItemWrap(VALUE klass, QGraphicsItem *item)
{
  return Data_Wrap_Struct(klass, cGraphicsItem_mark, 0, item);
}

enum { 
  R_QT_INTERNAL_GI_KEY, // VALUE parked here
  R_QT_NAME_GI_KEY, // objectName parked here 
  R_QT_GI_KEY_COUNT
};

#if defined(DEBUG)
extern VALUE item2v(QGraphicsItem *);
#else // !DEBUG

static inline VALUE
item2v(QGraphicsItem *i)
{
  if (!i) return Qnil;
  const QVariant &rvalue = i->data(R_QT_INTERNAL_GI_KEY);
  if (!rvalue.isValid()) return Qnil;
  return rvalue.value<RValue>();
}
#endif // DEBUG

static inline QGraphicsItem *
v2item(VALUE v_q)
{
  GET_STRUCT(QGraphicsItem, q);
  q->setData(R_QT_INTERNAL_GI_KEY, QVariant::fromValue(RValue(v_q)));
  return q;
}

extern VALUE cGraphicsItem, cAbstractGraphicsShapeItem;

template <typename T> static inline void
GetQGraphicsItem_noDecl(VALUE v_o, T *&q)
{
#if defined(DEBUG)
  if (!rb_obj_is_kind_of(v_o, cGraphicsItem))
    rb_raise(rb_eTypeError, "SERIOUS PROGRAMMING ERROR: very bad cast to QGraphicsItem");
#endif // DEBUG
  GET_STRUCT(QGraphicsItem, o);
  q = dynamic_cast<T *>(o);
  if (!q) rb_raise(rb_eTypeError, "Bad cast to some kind of QGraphicsItem");
}

extern VALUE cRectF, cPointF, cSynthItem, cSizeF;

#define RQTDECLARE_GI(T, var) T *var; GetQGraphicsItem_noDecl<T>(v_##var, var)

#if defined(DEBUG)
#define RQTDECLSELF_GI(T) RQTDECLARE_GI(T, self)
#else // !DEBUG
#define RQTDECLSELF_GI(T) GET_STRUCT(T, self)
#endif // !DEBUG

static inline QRectF&
v2rect(VALUE v)
{
#if defined(DEBUG)
  if (!rb_obj_is_instance_of(v, cRectF))
    rb_raise(rb_eTypeError, "SERIOUS PROGRAMMING ERROR: very bad cast to QRectF");
#endif // DEBUG
  QRectF *r;
  Data_Get_Struct(v, QRectF, r);
  if (!r)
    rb_raise(rb_eTypeError, "Bad cast to QRectF");
  return *r;
};

extern void cRectF_free(QRectF *rect);

static inline VALUE
cRectFWrap(QRectF *rect)
{
  return Data_Wrap_Struct(cRectF, 0, cRectF_free, rect);
}

extern QRectF args2QRectF(int argc, VALUE *argv);
extern QPointF args2QPointF(int argc, VALUE *argv);

extern void cSizeF_free(QSizeF *pt);
extern void cPointF_free(QPointF *pt);

static inline VALUE
cSizeFWrap(QSizeF *pt)
{
  return Data_Wrap_Struct(cSizeF, 0, cSizeF_free, pt);
}

static inline VALUE
cSizeFWrap(const QSizeF &sz)
{
  return Data_Wrap_Struct(cSizeF, 0, cSizeF_free, new QSizeF(sz));
}

static inline VALUE
cPointFWrap(QPointF *pt)
{
  return Data_Wrap_Struct(cPointF, 0, cPointF_free, pt);
}

static inline VALUE
cPointFWrap(const QPointF &pt)
{
  return Data_Wrap_Struct(cPointF, 0, cPointF_free, new QPointF(pt));
}

static inline QPointF&
v2pt(VALUE v)
{
#if defined(DEBUG)
  if (!rb_obj_is_instance_of(v, cPointF))
    rb_raise(rb_eTypeError, "SERIOUS PROGRAMMING ERROR: very bad cast to QPointF");
#endif // DEBUG
  QPointF *r;
  Data_Get_Struct(v, QPointF, r);
  if (!r)
    rb_raise(rb_eTypeError, "Bad cast to QPointF");
  return *r;
};

static inline QSizeF&
v2sz(VALUE v)
{
#if defined(DEBUG)
  if (!rb_obj_is_instance_of(v, cSizeF))
    rb_raise(rb_eTypeError, "SERIOUS PROGRAMMING ERROR: very bad cast to QSizeF");
#endif // DEBUG
  QSizeF *r;
  Data_Get_Struct(v, QSizeF, r);
  if (!r)
    rb_raise(rb_eTypeError, "Bad cast to QSizeF");
  return *r;
};

extern QSizeF args2QSizeF(int argc, VALUE *argv);

} // namespace R_Qt 
#endif // _URQT_GRAPHICSITEM_H_
