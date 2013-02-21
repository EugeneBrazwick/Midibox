
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

//#define TRACE

#include <QtWidgets/QGraphicsLineItem>
#include "application.h"
#include "graphicsitem.h"
#include "pen.h"
#include "point.h"

namespace R_Qt {

R_QT_DEF_GRALLOCATOR(GraphicsLineItem)

// Context: Pen.parent=
static VALUE
cGraphicsLineItem_pen_set(VALUE v_self, VALUE v_pen)
{
  const RPP::QGraphicsItem<QGraphicsLineItem> self = v_self;
  const RPP::QPen pen = v_pen;
  self.iv_set("@pen", pen);
  self->setPen(*pen);
  return v_pen;
}

static VALUE
cGraphicsLineItem_from_set(int argc, VALUE *argv, VALUE v_self)
{
  const RPP::QGraphicsItem<QGraphicsLineItem> self = v_self;
  const QPointF &pt = ARGS2QPOINTF();
  QLineF ln = self->line();
  ln.setP1(pt);
  self->setLine(ln);
  return Qnil;
}

static VALUE
cGraphicsLineItem_from_get(VALUE v_self)
{
  const RPP::QGraphicsItem<QGraphicsLineItem> self = v_self;
  return cPointFWrap(self->line().p1());
}

static VALUE
cGraphicsLineItem_to_set(int argc, VALUE *argv, VALUE v_self)
{
  const RPP::QGraphicsItem<QGraphicsLineItem> self = v_self;
  const QPointF &pt = ARGS2QPOINTF();
  QLineF ln = self->line();
  ln.setP2(pt);
  self->setLine(ln);
  return Qnil;
}

static VALUE
cGraphicsLineItem_to_get(VALUE v_self)
{
  const RPP::QGraphicsItem<QGraphicsLineItem> self = v_self;
  return cPointFWrap(self->line().p2());
}

void
init_lineitem(RPP::Module mQt, RPP::Class cGraphicsItem)
{
  cGraphicsLineItem = mQt.define_class("GraphicsLineItem", cGraphicsItem);
  cGraphicsLineItem.define_alloc_func(cGraphicsLineItem_alloc)
		   .define_method("to=", cGraphicsLineItem_to_set)
		   .define_method("to_get", cGraphicsLineItem_to_get)
		   .define_method("from=", cGraphicsLineItem_from_set)
		   .define_method("from_get", cGraphicsLineItem_from_get)
		   .define_method("pen=", cGraphicsLineItem_pen_set)
		   ;
}

} // namespace R_Qt
