
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

//#define TRACE

#include <QtWidgets/QGraphicsLineItem>
#include "application.h"
#include "graphicsitem.h"
#include "pen.h"

namespace R_Qt {

R_QT_DEF_GRALLOCATOR(GraphicsLineItem)

static VALUE
cGraphicsLineItem_pen_set(VALUE v_self, VALUE v_pen)
{
  rb_iv_set(v_self, "@pen", v_pen);
  RQTDECLSELF_GI(QGraphicsLineItem);
  RQTDECLARE_PEN(pen);
  self->setPen(*pen);
  return v_pen;
}

static VALUE
cGraphicsLineItem_pen_get(VALUE v_self)
{
  return rb_iv_get(v_self, "@pen");
}

static VALUE
cGraphicsLineItem_from_set(int argc, VALUE *argv, VALUE v_self)
{
  RQTDECLSELF_GI(QGraphicsLineItem);
  const QPointF &pt = args2QPointF(argc, argv);
  QLineF ln = self->line();
  ln.setP1(pt);
  self->setLine(ln);
  return Qnil;
}

static VALUE
cGraphicsLineItem_from_get(VALUE v_self)
{
  RQTDECLSELF_GI(QGraphicsLineItem);
  return cPointFWrap(self->line().p1());
}

static VALUE
cGraphicsLineItem_to_set(int argc, VALUE *argv, VALUE v_self)
{
  RQTDECLSELF_GI(QGraphicsLineItem);
  const QPointF &pt = args2QPointF(argc, argv);
  QLineF ln = self->line();
  ln.setP2(pt);
  self->setLine(ln);
  return Qnil;
}

static VALUE
cGraphicsLineItem_to_get(VALUE v_self)
{
  RQTDECLSELF_GI(QGraphicsLineItem);
  return cPointFWrap(self->line().p2());
}

void
init_lineitem(VALUE mQt, VALUE cGraphicsItem)
{
  const VALUE cGraphicsLineItem = rb_define_class_under(mQt, "GraphicsLineItem", 
						 	cGraphicsItem);
  rb_define_alloc_func(cGraphicsLineItem, cGraphicsLineItem_alloc);
  rb_define_method(cGraphicsLineItem, "to=", RUBY_METHOD_FUNC(cGraphicsLineItem_to_set), -1);
  rb_define_method(cGraphicsLineItem, "to_get", RUBY_METHOD_FUNC(cGraphicsLineItem_to_get), 0);
  rb_define_method(cGraphicsLineItem, "from=", RUBY_METHOD_FUNC(cGraphicsLineItem_from_set), -1);
  rb_define_method(cGraphicsLineItem, "from_get", RUBY_METHOD_FUNC(cGraphicsLineItem_from_get), 0);
  rb_define_method(cGraphicsLineItem, "pen=", RUBY_METHOD_FUNC(cGraphicsLineItem_pen_set), 1);
  rb_define_method(cGraphicsLineItem, "pen_get", RUBY_METHOD_FUNC(cGraphicsLineItem_pen_get), 0);
  rb_funcall(cGraphicsLineItem, rb_intern("attr_dynamic"), 2, cPointF, CSTR2SYM("from"));
  rb_funcall(cGraphicsLineItem, rb_intern("attr_dynamic"), 2, cPointF, CSTR2SYM("to"));
}

} // namespace R_Qt
