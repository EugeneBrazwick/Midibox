
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

#include <QtWidgets/QGraphicsPolygonItem>
#include "graphicsitem.h"
#include "point.h"

namespace R_Qt {

static VALUE
cPolygonF = Qnil;

static void
cPolygonF_free(QPolygonF *poly)
{
  delete poly;
}

static inline VALUE
cPolygonFWrap(QPolygonF *poly)
{
  return Data_Wrap_Struct(cPolygonF, 0, cPolygonF_free, poly);
}

R_QT_DEF_ALLOCATOR_BASE1(PolygonF)

static inline QPolygonF&
v2poly(VALUE v)
{
#if defined(DEBUG)
  if (!rb_obj_is_instance_of(v, cPolygonF))
    rb_raise(rb_eTypeError, "SERIOUS PROGRAMMING ERROR: very bad cast to QPolygonF");
#endif // DEBUG
  QPolygonF *r;
  Data_Get_Struct(v, QPolygonF, r);
  if (!r)
    rb_raise(rb_eTypeError, "Bad cast to QPolygonF");
  return *r;
};

static void
init_poly(VALUE mQt)
{
  cPolygonF = rb_define_class_under(mQt, "Polygon", rb_cObject);
  rb_define_alloc_func(cPolygonF, cPolygonF_alloc);
}

static QPolygonF &
args2QPolygonF(int argc, VALUE *argv, QPolygonF &dst)
{
  VALUE *v_arg = argv;
  if (argc == 1 && TYPE(argv[0]) == T_ARRAY)
    {
      argc = RARRAY_LEN(argv[0]);
      argv = RARRAY_PTR(argv[0]);
    }
  for (int i = 0; i < argc; i++, v_arg++)
    {
      switch (TYPE(*v_arg))
	{
	case T_FIXNUM:
	case T_FLOAT:
	  {
	    const double x = NUM2DBL(*v_arg++);
	    if (++i == argc) rb_raise(rb_eArgError, "odd number of vertices in polygon");
	    const double y = NUM2DBL(*v_arg);
	    dst << QPointF(x, y);
	    break;
	  }
	case T_ARRAY:
	  {
	    if (RARRAY_LEN(*v_arg) != 2)
	      rb_raise(rb_eArgError, "a vertex must be a float-tuple");
	    VALUE * const a = RARRAY_PTR(*v_arg);
	    const double x = NUM2DBL(a[0]);
	    const double y = NUM2DBL(a[1]);
	    dst << QPointF(x, y);
	    break;
	  }
	case T_DATA:
	    if (rb_obj_is_instance_of(*v_arg, cPointF))
	      dst << v2pt(*v_arg);
	    else if (rb_obj_is_instance_of(*v_arg, cPolygonF))
	      dst << v2poly(*v_arg);
	    else 
	      rb_raise(rb_eTypeError, "Bad value %s for a vertex", INSPECT(*v_arg));
	    break;
	default:
	    rb_raise(rb_eTypeError, "Cannot make a point from %s", INSPECT(*v_arg));
	}
    } // for
  return dst;
} // args2QPolygonF

#define ARGS2QPOLYGONF(poly) args2QPolygonF(argc, argv, poly)

static VALUE
cGraphicsTriangleItem_points_set(int argc, VALUE *argv, VALUE v_self)
{
  QPolygonF poly;
  ARGS2QPOLYGONF(poly);
  if (poly.size() != 3) rb_raise(rb_eArgError, "a triangle must have exactly 3 vertices");
  RQTDECLSELF_GI(QGraphicsPolygonItem);
  self->setPolygon(poly);
  return Qnil;
}

R_QT_DEF_GRALLOCATOR(GraphicsPolygonItem)

static void
init_triangle(VALUE mQt, VALUE cGraphicsPolygonItem)
{
  const VALUE cGraphicsTriangleItem = rb_define_class_under(mQt, "GraphicsTriangleItem",
							    cGraphicsPolygonItem);
  rb_define_alloc_func(cGraphicsTriangleItem, cGraphicsPolygonItem_alloc);
  rb_define_method(cGraphicsTriangleItem, "points=", 
		   RUBY_METHOD_FUNC(cGraphicsTriangleItem_points_set), -1);
}

static VALUE
cGraphicsQuadItem_points_set(int argc, VALUE *argv, VALUE v_self)
{
  QPolygonF poly;
  ARGS2QPOLYGONF(poly);
  if (poly.size() != 4) rb_raise(rb_eArgError, "a quad must have exactly 4 vertices");
  RQTDECLSELF_GI(QGraphicsPolygonItem);
  self->setPolygon(poly);
  return Qnil;
}

static void
init_quad(VALUE mQt, VALUE cGraphicsPolygonItem)
{
  const VALUE cGraphicsQuadItem = rb_define_class_under(mQt, "GraphicsQuadItem",
							cGraphicsPolygonItem);
  rb_define_alloc_func(cGraphicsQuadItem, cGraphicsPolygonItem_alloc);
  rb_define_method(cGraphicsQuadItem, "points=", 
		   RUBY_METHOD_FUNC(cGraphicsQuadItem_points_set), -1);
}

static VALUE
cGraphicsPolygonItem_points_set(int argc, VALUE *argv, VALUE v_self)
{
  RQTDECLSELF_GI(QGraphicsPolygonItem);
  QPolygonF poly;
  self->setPolygon(ARGS2QPOLYGONF(poly));
  return Qnil;
}

/* We now have to make a choice.
 * We can return a ruby array, but this requires a lot
 * of small allocations.
 *
 * Or we can return a QPolygonF.
 * It is not too hard making it Enumerable. 
 * But enumeration would cause a lot of small allocations.
 * This can be mitigated using to_a first.
 */
static VALUE
cGraphicsPolygonItem_points_get(VALUE v_self)
{
  RQTDECLSELF_GI(QGraphicsPolygonItem);
  // we must make a copy since polygon() returns a temporary
  return cPolygonFWrap(new QPolygonF(self->polygon()));
}

static VALUE
cGraphicsPolygonItem_points(int argc, VALUE *argv, VALUE v_self)
{
  if (argc == 0)
    return cGraphicsPolygonItem_points_get(v_self);
  return cGraphicsPolygonItem_points_set(argc, argv, v_self);
}

void 
init_polygon(VALUE mQt, VALUE /*cGraphicsItem*/)
{
  init_poly(mQt);
  const VALUE cGraphicsPolygonItem = rb_define_class_under(mQt, "GraphicsPolygonItem", 
							   cAbstractGraphicsShapeItem);
  rb_define_alloc_func(cGraphicsPolygonItem, cGraphicsPolygonItem_alloc);
  rb_define_method(cGraphicsPolygonItem, "points=", 
		   RUBY_METHOD_FUNC(cGraphicsPolygonItem_points_set), -1);
  rb_define_method(cGraphicsPolygonItem, "points_get", 
		   RUBY_METHOD_FUNC(cGraphicsPolygonItem_points_get), 0);
  rb_define_method(cGraphicsPolygonItem, "points", 
		   RUBY_METHOD_FUNC(cGraphicsPolygonItem_points), -1);
  init_triangle(mQt, cGraphicsPolygonItem);
  init_quad(mQt, cGraphicsPolygonItem);
}

} // namespace R_Qt
