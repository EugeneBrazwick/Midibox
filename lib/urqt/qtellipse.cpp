
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

//#define TRACE

#include <QtWidgets/QGraphicsEllipseItem>
#include "application.h"
#include "graphicsitem.h"

namespace R_Qt {

/* This may be more dreadful than Scenes, since Items are not even QObjects.
 */
R_QT_DEF_GRALLOCATOR(GraphicsEllipseItem)

/** :call-seq:
 *	rect = other
 *	rect = pos, size
 *	rect = x, y, w, h
 */
static VALUE
cGraphicsEllipseItem_rect_set(int argc, VALUE *argv, VALUE v_self)
{
  trace("cGraphicsEllipseItem_rect_set");
  rb_check_frozen(v_self);
  RQTDECLSELF_GI(QGraphicsEllipseItem);
  self->setRect(args2QRectF(argc, argv));
  return Qnil;
}

static VALUE
cGraphicsEllipseItem_rect_get(VALUE v_self)
{
  trace("cGraphicsEllipseItem_rect_get");
  RQTDECLSELF_GI(QGraphicsEllipseItem);
  const QRectF &rect = self->rect();
  return cRectFWrap(new QRectF(rect));
}

void 
init_qtellipse(VALUE mQt, VALUE /*cGraphicsItem*/)
{
  const VALUE cGraphicsEllipseItem = rb_define_class_under(mQt, "GraphicsEllipseItem", cAbstractGraphicsShapeItem);
  rb_define_alloc_func(cGraphicsEllipseItem, cGraphicsEllipseItem_alloc);
  rb_define_method(cGraphicsEllipseItem, "rect=", RUBY_METHOD_FUNC(cGraphicsEllipseItem_rect_set), -1);
  rb_define_method(cGraphicsEllipseItem, "rect_get", RUBY_METHOD_FUNC(cGraphicsEllipseItem_rect_get), 0);
}

} // namespace R_Qt
