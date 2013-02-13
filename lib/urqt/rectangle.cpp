
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

//#define TRACE

#include <QtWidgets/QGraphicsRectItem>
#include <QtGui/QPen>
#include "application.h"
#include "size.h"
#include "point.h"
#include "graphicsitem.h"

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
init_pointitem()
{
  const VALUE cGraphicsPointItem = rb_define_class_under(mQt, "GraphicsPointItem", 
						 	 cAbstractGraphicsShapeItem);
  rb_define_alloc_func(cGraphicsPointItem, cGraphicsPointItem_alloc);
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
  rb_check_frozen(v_self);
  RQTDECLSELF_GI(QGraphicsRectItem);
  self->setRect(ARGS2QRECTF());
  return Qnil;
}

static VALUE
cGraphicsRectItem_rect_get(VALUE v_self)
{
  trace("cGraphicsRectItem_rect_get");
  RQTDECLSELF_GI(QGraphicsRectItem);
  return cRectFWrap(self->rect());
}

static VALUE
cGraphicsRectItem_size_set(int argc, VALUE *argv, VALUE v_self)
{
  trace("cGraphicsRectItem_size_set");
  rb_check_frozen(v_self);
  RQTDECLSELF_GI(QGraphicsRectItem);
  QRectF r = self->rect();
  r.setSize(ARGS2QSIZEF());
  self->setRect(r);
  return Qnil;
}

static VALUE
cGraphicsRectItem_size_get(VALUE v_self)
{
  trace("cGraphicsRectItem_size_get");
  RQTDECLSELF_GI(QGraphicsRectItem);
  return cSizeFWrap(self->rect().size());
}

#define QT_GRI_CORNERMETHODS(Corner, corner, alias) \
static VALUE \
cGraphicsRectItem_##corner##_set(int argc, VALUE *argv, VALUE v_self) \
{ \
  trace("cGraphicsRectItem_" #corner "_set"); \
  rb_check_frozen(v_self); \
  RQTDECLSELF_GI(QGraphicsRectItem); \
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
  RQTDECLSELF_GI(QGraphicsRectItem); \
  return cPointFWrap(self->rect().corner()); \
}

#define QT_GRI_CORNERS \
  QT_GRI_CORNERMETHODS(TopLeft, topLeft, topleft) \
  QT_GRI_CORNERMETHODS(TopRight, topRight, topright) \
  QT_GRI_CORNERMETHODS(BottomLeft, bottomLeft, bottomleft) \
  QT_GRI_CORNERMETHODS(BottomRight, bottomRight, bottomright)

QT_GRI_CORNERS

#undef QT_GRI_CORNERMETHODS

#define QT_GRI_SIDEMETHODS(Side, side) \
static VALUE \
cGraphicsRectItem_##side##_set(VALUE v_self, VALUE v_sz) \
{ \
  trace("cGraphicsRectItem_" #side "_set"); \
  rb_check_frozen(v_self); \
  RQTDECLSELF_GI(QGraphicsRectItem); \
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
  RQTDECLSELF_GI(QGraphicsRectItem); \
  return DBL2NUM(self->rect().side()); \
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
init_rectangle(VALUE mQt, VALUE /*cGraphicsItem*/)
{
  const VALUE cGraphicsRectItem = rb_define_class_under(mQt, "GraphicsRectItem", 
							cAbstractGraphicsShapeItem);
  rb_define_alloc_func(cGraphicsRectItem, cGraphicsRectItem_alloc);
  rb_define_method(cGraphicsRectItem, "rect=", 
		   RUBY_METHOD_FUNC(cGraphicsRectItem_rect_set), -1);
  rb_define_method(cGraphicsRectItem, "rect_get", 
		   RUBY_METHOD_FUNC(cGraphicsRectItem_rect_get), 0);
  rb_funcall(cGraphicsRectItem, rb_intern("attr_dynamic"), 2, cRectF, CSTR2SYM("rect"));
  rb_define_method(cGraphicsRectItem, "size=", 
		   RUBY_METHOD_FUNC(cGraphicsRectItem_size_set), -1);
  rb_define_method(cGraphicsRectItem, "size_get", 
		   RUBY_METHOD_FUNC(cGraphicsRectItem_size_get), 0);
  rb_funcall(cGraphicsRectItem, rb_intern("attr_dynamic"), 2, cSizeF, CSTR2SYM("size"));
#define QT_GRI_CORNERMETHODS(Corner, corner, alias) \
  rb_define_method(cGraphicsRectItem, #corner "=", \
		   RUBY_METHOD_FUNC(cGraphicsRectItem_##corner##_set), -1); \
  rb_define_method(cGraphicsRectItem, #corner "_get", \
		   RUBY_METHOD_FUNC(cGraphicsRectItem_##corner##_get), 0); \
  rb_funcall(cGraphicsRectItem, rb_intern("attr_dynamic"), 2, cPointF, \
	     CSTR2SYM(#corner)); \
  rb_define_alias(cGraphicsRectItem, #alias, #corner);
  QT_GRI_CORNERS
#define QT_GRI_SIDEMETHODS(Side, side) \
  rb_define_method(cGraphicsRectItem, #side "=", \
		   RUBY_METHOD_FUNC(cGraphicsRectItem_##side##_set), 1); \
  rb_define_method(cGraphicsRectItem, #side "_get", \
		   RUBY_METHOD_FUNC(cGraphicsRectItem_##side##_get), 0); \
  rb_funcall(cGraphicsRectItem, rb_intern("attr_dynamic"), 2, rb_cFloat, CSTR2SYM(#side));
  QT_GRI_SIDES
  init_pointitem();
}

} // namespace R_Qt
