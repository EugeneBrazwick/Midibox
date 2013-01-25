
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

#include <QtWidgets/QGraphicsEllipseItem>
#include "application.h"
#include "graphicsitem.h"

namespace R_Qt {

/* This may be more dreadful than Scenes, since Items are NOT even QObjects.
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
  rb_check_frozen(v_self);
  RQTDECLSELF_GI(QGraphicsEllipseItem);
  VALUE v_x, v_y, v_w, v_h;
  rb_scan_args(argc, argv, "13", &v_x, &v_y, &v_w, &v_h);
  if (NIL_P(v_y))
    {
      // v_x is a RectF (or an array[4]?)
      self->setRect(v2rect(v_x));
    }
  else if (NIL_P(v_w))
    { 
      const VALUE v_pos = to_ary(v_x);
      const VALUE v_sz = to_ary(v_y);
      self->setRect(NUM2DBL(rb_ary_entry(v_pos, 0)), NUM2DBL(rb_ary_entry(v_pos, 1)),
		    NUM2DBL(rb_ary_entry(v_sz, 0)), NUM2DBL(rb_ary_entry(v_sz, 1)));
    }
  else
      self->setRect(NUM2DBL(v_x), NUM2DBL(v_y), NUM2DBL(v_w), NUM2DBL(v_h));
  return Qnil;
}

static VALUE
cGraphicsEllipseItem_rect_get(VALUE v_self)
{
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
