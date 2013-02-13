
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
  RQTDECLSELF_GI(QGraphicsPathItem);
  RQTDECLARE_PAINTERPATH(path); 
  self->setPath(*path);
  return v_path;
}

static VALUE
cBezierCurve_initialize(int argc, VALUE *argv, VALUE v_self)
{
  rb_call_super(argc, argv);
  rb_iv_set(v_self, "@c1", cPointFWrap(QPointF(0, 0))); 
  rb_iv_set(v_self, "@c2", cPointFWrap(QPointF(0, 0))); 
  rb_iv_set(v_self, "@from", cPointFWrap(QPointF(0, 0))); 
  rb_iv_set(v_self, "@to", cPointFWrap(QPointF(0, 0))); 
  return Qnil;
}

static VALUE
assignQPath(VALUE v_self)
{
  QPainterPath path(v2pt(rb_iv_get(v_self, "@from")));
  path.cubicTo(v2pt(rb_iv_get(v_self, "@c1")),
	       v2pt(rb_iv_get(v_self, "@c2")),
	       v2pt(rb_iv_get(v_self, "@to")));
  RQTDECLSELF_GI(QGraphicsPathItem);
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
init_bezier(VALUE mQt, VALUE cGraphicsPathItem)
{
  const VALUE cBezierCurve = rb_define_class_under(mQt, "BezierCurve", cGraphicsPathItem);
  // can we skip the alloc?  Then it can be dropped in polygon and rectangle too
  rb_define_private_method(cBezierCurve, "initialize", RUBY_METHOD_FUNC(cBezierCurve_initialize), -1);
  rb_define_private_method(cBezierCurve, "from=", RUBY_METHOD_FUNC(cBezierCurve_from_set), -1);
  rb_define_private_method(cBezierCurve, "from_get", RUBY_METHOD_FUNC(cBezierCurve_from_get), -1);
  rb_define_private_method(cBezierCurve, "to=", RUBY_METHOD_FUNC(cBezierCurve_to_set), -1);
  rb_define_private_method(cBezierCurve, "to_get", RUBY_METHOD_FUNC(cBezierCurve_to_get), -1);
  rb_define_private_method(cBezierCurve, "c1=", RUBY_METHOD_FUNC(cBezierCurve_c1_set), -1);
  rb_define_private_method(cBezierCurve, "c1_get", RUBY_METHOD_FUNC(cBezierCurve_c1_get), -1);
  rb_define_private_method(cBezierCurve, "c2=", RUBY_METHOD_FUNC(cBezierCurve_c2_set), -1);
  rb_define_private_method(cBezierCurve, "c2_get", RUBY_METHOD_FUNC(cBezierCurve_c2_get), -1);
  rb_funcall(cBezierCurve, rb_intern("attr_dynamic"), 2, cPointF, CSTR2SYM("from"));
  rb_funcall(cBezierCurve, rb_intern("attr_dynamic"), 2, cPointF, CSTR2SYM("to"));
  rb_funcall(cBezierCurve, rb_intern("attr_dynamic"), 2, cPointF, CSTR2SYM("c1"));
  rb_funcall(cBezierCurve, rb_intern("attr_dynamic"), 2, cPointF, CSTR2SYM("c2"));
}

R_QT_DEF_GRALLOCATOR(GraphicsPathItem)

void 
init_pathitem(VALUE mQt, VALUE /*cGraphicsItem*/)
{
  const VALUE cGraphicsPathItem = rb_define_class_under(mQt, "GraphicsPathItem",
							cAbstractGraphicsShapeItem);
  rb_define_alloc_func(cGraphicsPathItem, cGraphicsPathItem_alloc);
  rb_define_method(cGraphicsPathItem, "path=", RUBY_METHOD_FUNC(cGraphicsPathItem_path_set), 1);
  //  static VALUE cPathBuilder = rb_define_class_under(cGraphicsPathItem, "Builder", rb_cObject); 
    // Builder is written in ruby for debugging reasons, see pathitem.rb
  init_bezier(mQt, cGraphicsPathItem);
}

} // namespace R_Qt 
