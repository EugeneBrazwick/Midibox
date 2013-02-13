
// Copyright (c) 2013 Eugene Brazwick

#pragma implementation
#include "point.h"
#include "api_utils.h"

namespace R_Qt {

VALUE
cPointF = Qnil,
cPoint = Qnil; 

void
cPointF_free(QPointF *pt)
{
  delete pt;
}

R_QT_DEF_ALLOCATOR_BASE1(PointF)

QPointF
args2QPointF(int argc, VALUE *argv)
{
  trace1("args2QPointF, argc=%d", argc);
  VALUE v_w, v_h;
  rb_scan_args(argc, argv, "11", &v_w, &v_h);
  if (NIL_P(v_h) && TYPE(v_w) == T_ARRAY)
    {
      switch (RARRAY_LEN(v_w))
	{
	case 2:
	  v_h = RARRAY_PTR(v_w)[1];
	  // fall through
	case 1:
	  v_w = RARRAY_PTR(v_w)[0];
	  break;
	default:
	  rb_raise(rb_eTypeError, "invalid arrahlength for a point");
	}
    }
  if (NIL_P(v_h))
    {
      track1("v_w = %s", v_w);
      switch (TYPE(v_w))
	{
	case T_DATA:
	    // v_w should be a PointF 
	    return v2pt(v_w);
	case T_FIXNUM:
	case T_FLOAT:
	  {
	    const double w = NUM2DBL(v_w);
	    return QPointF(w, w);
	  }
	}
      rb_raise(rb_eTypeError, "invalid value %s to construct a point", INSPECT(v_w));
    }
  return QPointF(NUM2DBL(v_w), NUM2DBL(v_h));
}

void
cPoint_free(QPoint *pt)
{
  delete pt;
}

R_QT_DEF_ALLOCATOR_BASE1(Point)

QPoint
args2QPoint(int argc, VALUE *argv)
{
  trace1("args2QPoint, argc=%d", argc);
  VALUE v_w, v_h;
  rb_scan_args(argc, argv, "11", &v_w, &v_h);
  if (NIL_P(v_h) && TYPE(v_w) == T_ARRAY)
    {
      switch (RARRAY_LEN(v_w))
	{
	case 2:
	  v_h = RARRAY_PTR(v_w)[1];
	  // fall through
	case 1:
	  v_w = RARRAY_PTR(v_w)[0];
	  break;
	default:
	  rb_raise(rb_eTypeError, "invalid arrahlength for a point");
	}
    }
  if (NIL_P(v_h))
    {
      track1("v_w = %s", v_w);
      switch (TYPE(v_w))
	{
	case T_DATA:
	    // v_w should be a Point 
	    return v2point(v_w);
	case T_FIXNUM:
	  {
	    const double w = NUM2INT(v_w);
	    return QPoint(w, w);
	  }
	}
      rb_raise(rb_eTypeError, "invalid value %s to construct a point", INSPECT(v_w));
    }
  return QPoint(NUM2INT(v_w), NUM2INT(v_h));
}

// CONTEXT: init_graphicsitem()
void 
init_point(VALUE mQt)
{
  cPointF = rb_define_class_under(mQt, "PointF", rb_cObject);
  rb_define_alloc_func(cPointF, cPointF_alloc);
  cPoint = rb_define_class_under(mQt, "Point", rb_cObject);
  rb_define_alloc_func(cPoint, cPoint_alloc);
}

} // namespace R_Qt 
