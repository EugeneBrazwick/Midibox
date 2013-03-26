
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

//#define TRACE

#include <QtWidgets/QGraphicsRectItem>
#include <QtGui/QPen>
#include "application.h"
#include "size.h"
#include "point.h"
#include "graphicsitem.h"
#include "ruby++/numeric.h"
#include "ruby++/symbol.h"

namespace R_Qt {

class QGraphicsPointItem: public QGraphicsRectItem
{
private:
  typedef QGraphicsRectItem inherited;
  static const double Radius;
public:
  QGraphicsPointItem();
  void setPen(const QPen &pen)
    {
      setBrush(QBrush(pen.color()));
    }
  void setBrush(const QBrush &) {}
};

const double 
QGraphicsPointItem::Radius = 0.5;

QGraphicsPointItem::QGraphicsPointItem():
inherited(-Radius, -Radius, 2 * Radius, 2 * Radius)
{
}

R_QT_DEF_GRALLOCATOR(GraphicsPointItem)

static void
init_pointitem(RPP::Module mQt)
{
  const RPP::Class cGraphicsPointItem = mQt.define_class("GraphicsPointItem", 
						 	 cAbstractGraphicsShapeItem);
  cGraphicsPointItem.define_alloc_func(cGraphicsPointItem_alloc);
}

R_QT_DEF_GRALLOCATOR(GraphicsRectItem)

/** :call-seq:
 *	rect = other
 *	rect = pos, size
 *	rect = x, y, w, h
 */
static VALUE
cGraphicsRectItem_rect_set(int argc, VALUE *argv, VALUE v_self)
{
  trace("cGraphicsRectItem_rect_set");
  const RPP::QGraphicsItem<QGraphicsRectItem> self = v_self;
  self.check_frozen();
  self->setRect(ARGS2QRECTF());
  return Qnil;
}

static VALUE
cGraphicsRectItem_rect_get(VALUE v_self)
{
  trace("cGraphicsRectItem_rect_get");
  const RPP::QGraphicsItem<QGraphicsRectItem> self = v_self;
  return cRectFWrap(self->rect());
}

static VALUE
cGraphicsRectItem_size_set(int argc, VALUE *argv, VALUE v_self)
{
  trace("cGraphicsRectItem_size_set");
  const RPP::QGraphicsItem<QGraphicsRectItem> self = v_self;
  self.check_frozen();
  QRectF r = self->rect();
  r.setSize(RPP::QSizeF(argc, argv));
  self->setRect(r);
  return Qnil;
}

static VALUE
cGraphicsRectItem_size_get(VALUE v_self)
{
  trace("cGraphicsRectItem_size_get");
  const RPP::QGraphicsItem<QGraphicsRectItem> self = v_self;
  return RPP::QSizeF(self->rect().size());
}

#define QT_GRI_CORNERMETHODS(Corner, corner) \
static VALUE \
cGraphicsRectItem_##corner##_set(int argc, VALUE *argv, VALUE v_self) \
{ \
  trace("cGraphicsRectItem_" #corner "_set"); \
  const RPP::QGraphicsItem<QGraphicsRectItem> self = v_self; \
  self.check_frozen(); \
  QRectF r = self->rect(); \
  r.set##Corner(ARGS2QPOINTF()); \
  self->setRect(r); \
  return Qnil; \
} \
 \
static VALUE \
cGraphicsRectItem_##corner##_get(VALUE v_self) \
{ \
  trace("cGraphicsRectItem_" #corner "_get"); \
  const RPP::QGraphicsItem<QGraphicsRectItem> self = v_self; \
  return cPointFWrap(self->rect().corner()); \
}

#define QT_GRI_CORNERS \
  QT_GRI_CORNERMETHODS(TopLeft, topLeft) \
  QT_GRI_CORNERMETHODS(TopRight, topRight) \
  QT_GRI_CORNERMETHODS(BottomLeft, bottomLeft) \
  QT_GRI_CORNERMETHODS(BottomRight, bottomRight)

QT_GRI_CORNERS

#undef QT_GRI_CORNERMETHODS

#define QT_GRI_SIDEMETHODS(Side, side) \
static VALUE \
cGraphicsRectItem_##side##_set(VALUE v_self, VALUE v_sz) \
{ \
  trace("cGraphicsRectItem_" #side "_set"); \
  const RPP::QGraphicsItem<QGraphicsRectItem> self = v_self; \
  self.check_frozen(); \
  QRectF r = self->rect(); \
  r.set##Side(NUM2DBL(v_sz)); \
  self->setRect(r); \
  return Qnil; \
} \
 \
static VALUE \
cGraphicsRectItem_##side##_get(VALUE v_self) \
{ \
  trace("cGraphicsRectItem_" #side "_get"); \
  const RPP::QGraphicsItem<QGraphicsRectItem> self = v_self; \
  return RPP::Float(self->rect().side()); \
}

#define QT_GRI_SIDES \
  QT_GRI_SIDEMETHODS(Left, left) \
  QT_GRI_SIDEMETHODS(Top, top) \
  QT_GRI_SIDEMETHODS(Bottom, bottom) \
  QT_GRI_SIDEMETHODS(Right, right) \
  QT_GRI_SIDEMETHODS(Width, width) \
  QT_GRI_SIDEMETHODS(Height, height)

QT_GRI_SIDES

#undef QT_GRI_SIDEMETHODS

void 
init_rectangle(RPP::Module mQt, RPP::Class /*cGraphicsItem*/)
{
  const RPP::Class cGraphicsRectItem = mQt.define_class("GraphicsRectItem", 
							cAbstractGraphicsShapeItem);
  cGraphicsRectItem.define_alloc_func(cGraphicsRectItem_alloc)
		   .define_method("rect=", cGraphicsRectItem_rect_set)
		   .define_method("rect_get", cGraphicsRectItem_rect_get)
		   .define_method("size=", cGraphicsRectItem_size_set)
		   .define_method("size_get", cGraphicsRectItem_size_get)
		   ;
#define QT_GRI_CORNERMETHODS(Corner, corner) \
  cGraphicsRectItem.define_method(#corner "=", cGraphicsRectItem_##corner##_set) \
		   .define_method(#corner "_get", cGraphicsRectItem_##corner##_get);
		  QT_GRI_CORNERS
#define QT_GRI_SIDEMETHODS(Side, side) \
  cGraphicsRectItem.define_method(#side "=", cGraphicsRectItem_##side##_set) \
		   .define_method(#side "_get", cGraphicsRectItem_##side##_get); 
		  QT_GRI_SIDES
		  ;
  init_pointitem(mQt);
}

} // namespace R_Qt
