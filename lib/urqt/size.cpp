
// Copyright (c) 2013 Eugene Brazwick

#pragma implementation
#include "size.h"
#include "api_utils.h"

namespace R_Qt {

VALUE
cSizeF = Qnil,
cSize = Qnil; 

void
cSizeF_free(QSizeF *pt)
{
  delete pt;
}

R_QT_DEF_ALLOCATOR_BASE1(SizeF)

QSizeF
args2QSizeF(int argc, VALUE *argv)
{
  trace1("args2QSizeF, argc=%d", argc);
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
	  rb_raise(rb_eTypeError, "invalid arrahlength for a size");
	}
    }
  if (NIL_P(v_h))
    {
      track1("v_w = %s", v_w);
      switch (TYPE(v_w))
	{
	case T_DATA:
	    // v_w should be a SizeF 
	    return v2sz(v_w);
	case T_FIXNUM:
	case T_FLOAT:
	  {
	    const double w = NUM2DBL(v_w);
	    return QSizeF(w, w);
	  }
	}
      rb_raise(rb_eTypeError, "invalid value %s to construct a size", INSPECT(v_w));
    }
  return QSizeF(NUM2DBL(v_w), NUM2DBL(v_h));
}

void
cSize_free(QSize *pt)
{
  delete pt;
}

R_QT_DEF_ALLOCATOR_BASE1(Size)

QSize
args2QSize(int argc, VALUE *argv)
{
  trace1("args2QSize, argc=%d", argc);
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
	  rb_raise(rb_eTypeError, "invalid arrahlength for a size");
	}
    }
  if (NIL_P(v_h))
    {
      track1("v_w = %s", v_w);
      switch (TYPE(v_w))
	{
	case T_DATA:
	    // v_w should be a Size 
	    return v2size(v_w);
	case T_FIXNUM:
	  {
	    const double w = NUM2INT(v_w);
	    return QSize(w, w);
	  }
	}
      rb_raise(rb_eTypeError, "invalid value %s to construct a size", INSPECT(v_w));
    }
  return QSize(NUM2INT(v_w), NUM2INT(v_h));
}

static VALUE
cSize_height(VALUE v_self)
{
  return INT2NUM(v2size(v_self).height());
}

static VALUE
cSize_width(VALUE v_self)
{
  return INT2NUM(v2size(v_self).width());
}

static VALUE
cSizeF_height(VALUE v_self)
{
  return DBL2NUM(v2sz(v_self).height());
}

static VALUE
cSizeF_width(VALUE v_self)
{
  return DBL2NUM(v2sz(v_self).width());
}

// CONTEXT: init_graphicsitem()
void 
init_size(VALUE mQt)
{
  cSizeF = rb_define_class_under(mQt, "SizeF", rb_cObject);
  rb_define_alloc_func(cSizeF, cSizeF_alloc);
  cSize = rb_define_class_under(mQt, "Size", rb_cObject);
  rb_define_alloc_func(cSize, cSize_alloc);
#define DEF_SZ_METHODS(cls) \
  rb_define_method(cls, "height", RUBY_METHOD_FUNC(cls##_height), 0); \
  rb_define_method(cls, "width", RUBY_METHOD_FUNC(cls##_width), 0); \
  rb_define_alias(cls, "w", "width"); \
  rb_define_alias(cls, "h", "height"); \

  DEF_SZ_METHODS(cSizeF);
  DEF_SZ_METHODS(cSize);
}

} // namespace R_Qt 
