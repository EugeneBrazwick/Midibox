#if !defined(_URQT_GRAPHICSITEM_H_)
#define _URQT_GRAPHICSITEM_H_

// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

#include <QtWidgets/QGraphicsItem>
#include <typeinfo>
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

extern RPP::Class cGraphicsItem, cAbstractGraphicsShapeItem, cGraphicsScene,
		  cGraphicsLineItem;

template <typename T> static inline void
GetQGraphicsItem_noDecl(VALUE v_o, T *&q, const char *type)
{
#if defined(DEBUG)
  if (!rb_obj_is_kind_of(v_o, cGraphicsItem))
    rb_raise(rb_eTypeError, "SERIOUS PROGRAMMING ERROR: very bad cast to QGraphicsItem");
#endif // DEBUG
  GET_STRUCT(QGraphicsItem, o);
  q = dynamic_cast<T *>(o);
  if (!q) rb_raise(rb_eTypeError, "Bad cast from %s (qtptr: %p) to %s", INSPECT(v_o), o, type);
}

extern RPP::Class cRectF, cSynthItem;

#define RQTDECLARE_GI(T, var) T *var; GetQGraphicsItem_noDecl<T>(v_##var, var, #T)

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

static inline VALUE
cRectFWrap(const QRectF &rect)
{
  return Data_Wrap_Struct(cRectF, 0, cRectF_free, new QRectF(rect));
}

extern QRectF args2QRectF(int argc, VALUE *argv);

#define ARGS2QRECTF() args2QRectF(argc, argv)

} // namespace R_Qt 

namespace RPP {
// T must be a ::QGraphicsItem (sub)class
template <class T>class QGraphicsItem: public DataObject<T>
{
private:
  typedef DataObject<T> inherited;
public:
  QGraphicsItem<T>(VALUE v_o): inherited(v_o, R_Qt::cGraphicsItem)
    {
      ::QGraphicsItem * const o = this->wrapped();
      if (!dynamic_cast<T *>(o))
	rb_raise(rb_eTypeError, "Bad cast from %s (qtptr: %p) to %s", INSPECT(v_o), o, typeid(T).name());
    }
  QGraphicsItem<T>(T *gi, E_SAFETY /*VERYUNSAFE*/): inherited(R_Qt::item2v(gi), gi) {}
}; // class RPP::QGraphicsItem

} // namespace RPP 
#endif // _URQT_GRAPHICSITEM_H_
