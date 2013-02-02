
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

//#define TRACE

#include <QtWidgets/QGraphicsRectItem>
#include <QtGui/QPen>
#include "application.h"
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
init_point()
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
  self->setRect(args2QRectF(argc, argv));
  return Qnil;
}

static VALUE
cGraphicsRectItem_rect_get(VALUE v_self)
{
  trace("cGraphicsRectItem_rect_get");
  RQTDECLSELF_GI(QGraphicsRectItem);
  return cRectFWrap(new QRectF(self->rect()));
}

void 
init_rectangle(VALUE mQt, VALUE /*cGraphicsItem*/)
{
  const VALUE cGraphicsRectItem = rb_define_class_under(mQt, "GraphicsRectItem", 
							cAbstractGraphicsShapeItem);
  rb_define_alloc_func(cGraphicsRectItem, cGraphicsRectItem_alloc);
  rb_define_method(cGraphicsRectItem, "rect=", RUBY_METHOD_FUNC(cGraphicsRectItem_rect_set), -1);
  rb_define_method(cGraphicsRectItem, "rect_get", RUBY_METHOD_FUNC(cGraphicsRectItem_rect_get), 0);
  rb_funcall(cGraphicsRectItem, rb_intern("attr_dynamic"), 2, cRectF, CSTR2SYM("rect"));
  init_point();
}

} // namespace R_Qt
