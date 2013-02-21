
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
  const RPP::QGraphicsItem<QGraphicsEllipseItem> self = v_self;
  self.check_frozen();
  self->setRect(args2QRectF(argc, argv));
  return Qnil;
}

static VALUE
cGraphicsEllipseItem_rect_get(VALUE v_self)
{
  trace("cGraphicsEllipseItem_rect_get");
  const RPP::QGraphicsItem<QGraphicsEllipseItem> self = v_self;
  const QRectF &rect = self->rect();
  return cRectFWrap(new QRectF(rect));
}

void 
init_qtellipse(RPP::Module mQt, RPP::Class/*cGraphicsItem*/)
{
  const RPP::Class cGraphicsEllipseItem = mQt.define_class("GraphicsEllipseItem", cAbstractGraphicsShapeItem);
  cGraphicsEllipseItem.define_alloc_func(cGraphicsEllipseItem_alloc)
		      .define_method("rect=", cGraphicsEllipseItem_rect_set)
		      .define_method("rect_get", cGraphicsEllipseItem_rect_get)
		      ;
}

} // namespace R_Qt
