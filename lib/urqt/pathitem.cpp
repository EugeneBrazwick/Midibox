
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

#include <QtWidgets/QGraphicsPathItem>
#include "graphicsitem.h"
#include "painterpath.h"
#include "point.h"

namespace R_Qt {

static VALUE
cGraphicsPathItem_path_set(VALUE v_self, VALUE v_path)
{
  const RPP::QGraphicsItem<QGraphicsPathItem> self = v_self;
  RQTDECLARE_PAINTERPATH(path);
  self->setPath(*path);
  return v_path;
}

static VALUE
cBezierCurve_initialize(int argc, VALUE *argv, VALUE v_self)
{
  const RPP::Object self = v_self;
  self.super(argc, argv);
  self.iv_set("@c1", cPointFWrap(QPointF(0, 0))) 
      .iv_set("@c2", cPointFWrap(QPointF(0, 0)))
      .iv_set("@from", cPointFWrap(QPointF(0, 0)))
      .iv_set("@to", cPointFWrap(QPointF(0, 0)))
      ; 
  return Qnil;
}

static VALUE
assignQPath(VALUE v_self)
{
  const RPP::QGraphicsItem<QGraphicsPathItem> self = v_self;
  QPainterPath path(v2pt(self.iv("@from")));
  path.cubicTo(v2pt(self.iv("@c1")),
	       v2pt(self.iv("@c2")),
	       v2pt(self.iv("@to")));
  self->setPath(path);
  return Qnil;
}

#define BEZIER_CURVE_GETSET(term) \
  static VALUE \
  cBezierCurve_##term##_set(int argc, VALUE *argv, VALUE v_self) \
  { \
    rb_iv_set(v_self, "@" #term, cPointFWrap(ARGS2QPOINTF())); \
    return assignQPath(v_self); \
  } \
 \
  static VALUE \
  cBezierCurve_##term##_get(VALUE v_self) \
  { \
    return rb_iv_get(v_self, "@" #term); \
  }

BEZIER_CURVE_GETSET(from)
BEZIER_CURVE_GETSET(to)
BEZIER_CURVE_GETSET(c1)
BEZIER_CURVE_GETSET(c2)

static void 
init_bezier(RPP::Module mQt, RPP::Class cGraphicsPathItem)
{
  const RPP::Class cBezierCurve = mQt.define_class("BezierCurve", cGraphicsPathItem);
  // can we skip the alloc?  Then it can be dropped in polygon and rectangle too
  cBezierCurve.define_private_method("initialize", cBezierCurve_initialize)
	      .define_private_method("from=", cBezierCurve_from_set)
	      .define_private_method("from_get", cBezierCurve_from_get)
	      .define_private_method("to=", cBezierCurve_to_set)
	      .define_private_method("to_get", cBezierCurve_to_get)
	      .define_private_method("c1=", cBezierCurve_c1_set)
	      .define_private_method("c1_get", cBezierCurve_c1_get)
	      .define_private_method("c2=", cBezierCurve_c2_set)
	      .define_private_method("c2_get", cBezierCurve_c2_get)
	      ;
}

R_QT_DEF_GRALLOCATOR(GraphicsPathItem)

void 
init_pathitem(RPP::Module mQt, RPP::Class/*cGraphicsItem*/)
{
  const RPP::Class cGraphicsPathItem = mQt.define_class("GraphicsPathItem", cAbstractGraphicsShapeItem);
  cGraphicsPathItem.define_alloc_func(cGraphicsPathItem_alloc)
		   .define_method("path=", cGraphicsPathItem_path_set)
		   ;
  //  static VALUE cPathBuilder = rb_define_class_under(cGraphicsPathItem, "Builder", rb_cObject); 
    // Builder is written in ruby for debugging reasons, see pathitem.rb
  init_bezier(mQt, cGraphicsPathItem);
}

} // namespace R_Qt 
