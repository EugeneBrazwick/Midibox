
// Copyright (c) 2013 Eugene Brazwick

//#define TRACE

#pragma implementation
#include "api_utils.h"
#include "size.h"
#include "ruby++/rppstring.h"
#include "ruby++/array.h"
#include "ruby++/bool.h"

namespace R_Qt {

RPP::Class
cSizeF,
cSize;

static VALUE
cSize_alloc(VALUE /*cSize*/)
{
  trace("cSize_alloc");
  return RPP::QSize(new QSize);
}

void
cSize_free(QSize *pt)
{
  delete pt;
}

static inline bool 
argcv2wh(RPP::Scan &scan, int &width, int &height)
{
  RPP::Object w, h;
  scan.opts(w, h);
  if (w.isNil())
    return false;
  track2("Scan -> %s %s", w, h);
  if (h.isNil() && w.isArray())
    {
      const RPP::Array hw(w, RPP::VERYUNSAFE);
      switch (hw.len())
	{
	case 2:
	  h = hw[1];
	  // fall through
	case 1:
	  w = hw[0];
	  break;
	default:
	  rb_raise(rb_eTypeError, "invalid arraylength for a QSize");
	}
    }
  if (h.isNil())
    {
      track1("w = %s", w);
      switch (w.type())
	{
	case T_DATA:
	  {
	    const RPP::QSize other(w);
	    width = other->width();
	    height = other->height();
	    break;
	  }
	case T_FIXNUM:
	  {
	    height = width = RPP::Fixnum(w);
	    break;
	  }
	default:
	    rb_raise(rb_eTypeError, "invalid value %s to construct a QSize", w.inspect());
	}
    }
  else
    {
      track2("w=%s, h=%s", w, h);
      width = w.to_i();
      height = h.to_i();
    }
  return true;
}

static inline bool 
argcv2wh(int argc, VALUE *argv, int &width, int &height)
{
  RPP::Scan scan(argc, argv);
  return argcv2wh(scan, width, height);
}

static VALUE
cSize_initialize(int argc, VALUE *argv, VALUE v_self)
{
  trace("cSize_initialize");
  RPP::QSize self = v_self;
  int width, height;
  if (argcv2wh(argc, argv, width, height))
    *self = QSize(width, height);
  return Qnil;
}

static VALUE
cSize_width(VALUE v_self)
{
  return RPP::Fixnum(RPP::QSize(v_self)->width());
}

static VALUE
cSize_height(VALUE v_self)
{
  return RPP::Fixnum(RPP::QSize(v_self)->height());
}

static VALUE
cSize_width_set(VALUE v_self, VALUE v_w)
{
  track2("%s::width= %s", v_self, v_w);
  const RPP::QSize self = v_self;
  self.check_frozen();
  self->setWidth(RPP::Fixnum(v_w));
  return v_w;
}

static VALUE
cSize_height_set(VALUE v_self, VALUE v_h)
{
  const RPP::QSize self = v_self;
  self.check_frozen();
  self->setHeight(RPP::Fixnum(v_h));
  return v_h;
}

static VALUE
cSize_assign(int argc, VALUE *argv, VALUE v_self)
{
  RPP::QSize self = v_self;
  self.check_frozen();
  int width, height;
  if (!argcv2wh(argc, argv, width, height))
    *self = QSize();
  else
    *self = QSize(width, height);
  return v_self;
}

static VALUE
cSize_empty_p(VALUE v_self)
{
  return RPP::Bool(RPP::QSize(v_self)->isEmpty());
}

static VALUE
cSize_valid_p(VALUE v_self)
{
  return RPP::Bool(RPP::QSize(v_self)->isValid());
}

static VALUE
cSize_null_p(VALUE v_self)
{
  return RPP::Bool(RPP::QSize(v_self)->isNull());
}

static VALUE
cSize_add(VALUE v_self, VALUE v_other)
{
  int width, height;
  if (argcv2wh(1, &v_other, width, height))
    return RPP::QSize(*(RPP::QSize(v_self)) + QSize(width, height));
  return RPP::QSize(QSize());
}

static VALUE
cSize_substract(VALUE v_self, VALUE v_other)
{
  int width, height;
  if (argcv2wh(1, &v_other, width, height))
    return RPP::QSize(*(RPP::QSize(v_self)) - QSize(width, height));
  return RPP::QSize(QSize());
}

static VALUE
cSize_multiply(VALUE v_self, VALUE v_factor)
{
  return RPP::QSize(*(RPP::QSize(v_self)) * RPP::Float(v_factor));
}

static VALUE
cSize_divide(VALUE v_self, VALUE v_factor)
{
  return RPP::QSize(*(RPP::QSize(v_self)) / RPP::Float(v_factor));
}

static VALUE
cSize_equal_p(VALUE v_self, VALUE v_other)
{
  trace("cSize_equal_p");
  int width, height;
  if (argcv2wh(1, &v_other, width, height))
    return RPP::Bool(*RPP::QSize(v_self) == QSize(width, height));
  return RPP::Bool(*RPP::QSize(v_self) == QSize());
}

static VALUE
cSize_unequal_p(VALUE v_self, VALUE v_other)
{
  int width, height;
  if (argcv2wh(1, &v_other, width, height))
    return RPP::Bool(*RPP::QSize(v_self) != QSize(width, height));
  return RPP::Bool(*RPP::QSize(v_self) != QSize());
}

static VALUE
cSize_to_a(VALUE v_self)
{
  RPP::Array ary;
  const RPP::QSize self = v_self;
  ary << self->width() << self->height();
  return ary;
}

static VALUE
cSize_to_s(VALUE v_self)
{
  trace("inspect/to_s"); // cannot call inspect/to_s here !!
  const RPP::QSize self = v_self;
  if (!self->isValid()) return RPP::String("QSize<INVALID>");
  RPP::String res;
  res << "QSize(" << self->width() << ", " << self->height() << ")";
  track1("to_s, res='%s'", res);
  return res;
}

static Qt::AspectRatioMode
sym2arm(RPP::Symbol v_ar)
{
  Qt::AspectRatioMode m;
  if (v_ar == "ignoreAspectRatio")
    m = Qt::IgnoreAspectRatio;
  else if (v_ar == "keepAspectRatio")
    m = Qt::KeepAspectRatio;
  else if (v_ar == "keepAspectRatioByExpanding")
    m = Qt::KeepAspectRatioByExpanding;
  else
    rb_raise(rb_eArgError, "Unknown AspectRatioMode '%s'", v_ar.inspect());
  return m;
}

static VALUE
cSize_scaled(int argc, VALUE *argv, VALUE v_self)
{
  trace1("cSize_scaled, argc=%d", argc);
  RPP::Symbol v_ar;
  RPP::Scan scan(argc, argv);
  scan.tail_arg(v_ar);
  int width, height;
  trace1("tail scanned, left argc=%d", scan.argc());
  if (!argcv2wh(scan, width, height))
    return RPP::QSize(QSize());
  trace("calling Qt scaled()");
  const RPP::QSize self = v_self;
  return RPP::QSize(self->scaled(width, height, sym2arm(v_ar)));
}

static VALUE
cSize_scale(int argc, VALUE *argv, VALUE v_self)
{
  RPP::QSize self = v_self;
  self.check_frozen();
  RPP::QSize v_scaled = cSize_scaled(argc, argv, v_self);
  trace("then assign it");
  *self = *v_scaled;
  return v_self;
}

static VALUE
cSize_transposed(VALUE v_self)
{
  return RPP::QSize(RPP::QSize(v_self)->transposed());
}

static VALUE
cSize_transpose(VALUE v_self)
{
  const RPP::QSize self = v_self;
  self.check_frozen();
  self->transpose();
  return v_self;
}

static VALUE
cSize_boundedTo(VALUE v_self, VALUE v_other)
{
  int width, height;
  if (argcv2wh(1, &v_other, width, height))
    return RPP::QSize(RPP::QSize(v_self)->boundedTo(QSize(width, height)));
  return RPP::QSize(QSize());
}

static VALUE
cSize_expandedTo(VALUE v_self, VALUE v_other)
{
  int width, height;
  if (argcv2wh(1, &v_other, width, height))
    return RPP::QSize(RPP::QSize(v_self)->expandedTo(QSize(width, height)));
  return RPP::QSize(QSize());
}

static VALUE
cSizeF_alloc(VALUE /*cSizeF*/)
{
  trace("cSizeF_alloc");
  return RPP::QSizeF(new QSizeF);
}

void
cSizeF_free(QSizeF *pt)
{
  delete pt;
}

static inline bool
argcv2wh(RPP::Scan &scan, double &width, double &height)
{
  trace1("argcv2wh Float version, argc = %d", scan.argc());
  RPP::Object w, h;
  scan.opts(w, h);
  if (w.isNil()) return false;
  track2("Scan -> %s %s", w, h);
  if (h.isNil() && w.isArray())
    {
      const RPP::Array hw(w, RPP::VERYUNSAFE);
      track1("Detected single Array argv[0] = %s", hw);
      switch (hw.len())
	{
	case 2:
	  h = hw[1];
	  // fall through
	case 1:
	  w = hw[0];
	  break;
	default:
	  rb_raise(rb_eTypeError, "invalid arraylength for a QSize");
	}
    }
  track2("h=%s, w=%s", h, w);
  if (h.isNil())
    {
      switch (w.type())
	{
	case T_DATA:
	  if (w.is_kind_of(cSize))
	    {
	      const RPP::QSize other(w);
	      width = other->width();
	      height = other->height();
	    }
	  else
	    {
	      const RPP::QSizeF other(w);
	      width = other->width();
	      height = other->height();
	    }
	  break;
	case T_FIXNUM:
	  height = width = RPP::Fixnum(w);
	  break;
	case T_FLOAT:
	  height = width = RPP::Float(w);
	  break;
	default:
	  rb_raise(rb_eTypeError, "invalid value %s to construct a QSize", w.inspect());
	}
    }
  else
    {
      width = w.to_f();
      height = h.to_f();
    }
  trace2("Got width=%.4f and height=%.4f", width, height);
  return true;
}

static inline bool 
argcv2wh(int argc, VALUE *argv, double &width, double &height)
{
  RPP::Scan scan(argc, argv);
  return argcv2wh(scan, width, height);
}

static VALUE
cSizeF_initialize(int argc, VALUE *argv, VALUE v_self)
{
  trace1("cSizeF_initialize argc=%d", argc);
  RPP::QSizeF self = v_self;
  double width, height;
  if (argcv2wh(argc, argv, width, height))
    *self = QSizeF(width, height);
  return Qnil;
}

static VALUE
cSizeF_height(VALUE v_self)
{
  return RPP::Float(RPP::QSizeF(v_self)->height());
}

static VALUE
cSizeF_width(VALUE v_self)
{
  return RPP::Float(RPP::QSizeF(v_self)->width());
}

static VALUE
cSizeF_width_set(VALUE v_self, VALUE v_w)
{
  const RPP::QSizeF self = v_self;
  self.check_frozen();
  self->setWidth(RPP::Fixnum(v_w));
  return v_w;
}

static VALUE
cSizeF_height_set(VALUE v_self, VALUE v_h)
{
  const RPP::QSizeF self = v_self;
  self.check_frozen();
  self->setHeight(RPP::Fixnum(v_h));
  return v_h;
}

static VALUE
cSizeF_assign(int argc, VALUE *argv, VALUE v_self)
{
  RPP::QSizeF self = v_self;
  self.check_frozen();
  double width, height;
  if (!argcv2wh(argc, argv, width, height))
    *self = QSizeF();
  else
    *self = QSizeF(width, height);
  return v_self;
}

static VALUE
cSizeF_empty_p(VALUE v_self)
{
  return RPP::Bool(RPP::QSizeF(v_self)->isEmpty());
}

static VALUE
cSizeF_valid_p(VALUE v_self)
{
  return RPP::Bool(RPP::QSizeF(v_self)->isValid());
}

static VALUE
cSizeF_null_p(VALUE v_self)
{
  return RPP::Bool(RPP::QSizeF(v_self)->isNull());
}

static VALUE
cSizeF_add(VALUE v_self, VALUE v_other)
{
  double width, height;
  if (argcv2wh(1, &v_other, width, height))
    return RPP::QSizeF(*(RPP::QSizeF(v_self)) + QSizeF(width, height));
  return RPP::QSizeF(QSizeF());
}

static VALUE
cSizeF_substract(VALUE v_self, VALUE v_other)
{
  double width, height;
  if (argcv2wh(1, &v_other, width, height))
    return RPP::QSizeF(*(RPP::QSizeF(v_self)) - QSizeF(width, height));
  return RPP::QSizeF(QSizeF());
}

static VALUE
cSizeF_multiply(VALUE v_self, VALUE v_factor)
{
  return RPP::QSizeF(*(RPP::QSizeF(v_self)) * RPP::Float(v_factor));
}

static VALUE
cSizeF_divide(VALUE v_self, VALUE v_factor)
{
  return RPP::QSizeF(*(RPP::QSizeF(v_self)) / RPP::Float(v_factor));
}

static VALUE
cSizeF_equal_p(VALUE v_self, VALUE v_other)
{
  track2("cSizeF_equal_p, %s::==(%s)", v_self, v_other);
  double width, height;
  if (argcv2wh(1, &v_other, width, height))
    {
      trace("argcv2wh OK");
      return RPP::Bool(*RPP::QSizeF(v_self) == QSizeF(width, height));
    }
  return RPP::Bool(*RPP::QSizeF(v_self) == QSizeF());
}

static VALUE
cSizeF_unequal_p(VALUE v_self, VALUE v_other)
{
  double width, height;
  if (argcv2wh(1, &v_other, width, height))
    return RPP::Bool(*RPP::QSizeF(v_self) != QSizeF(width, height));
  return RPP::Bool(*RPP::QSizeF(v_self) != QSizeF());
}

static VALUE
cSizeF_to_a(VALUE v_self)
{
  RPP::Array ary;
  const RPP::QSizeF self = v_self;
  ary << self->width() << self->height();
  return ary;
}

static VALUE
cSizeF_to_s(VALUE v_self)
{
  trace("cSizeF_to_s/inspect");
  const RPP::QSizeF self = v_self;
  trace1("self.isValid=%d", (int)self->isValid());
  if (!self->isValid()) return RPP::String("QSizeF<INVALID>");
  RPP::String res;
  res << "QSizeF(" << self->width() << ", " << self->height() << ")";
  return res;
}

static VALUE
cSizeF_scaled(int argc, VALUE *argv, VALUE v_self)
{
  RPP::Symbol v_ar;
  RPP::Scan scan(argc, argv);
  scan.tail_arg(v_ar);
  double width, height;
  if (!argcv2wh(scan, width, height))
    return RPP::QSizeF(QSizeF());
  const RPP::QSizeF self = v_self;
  return RPP::QSizeF(self->scaled(width, height, sym2arm(v_ar)));
}

static VALUE
cSizeF_scale(int argc, VALUE *argv, VALUE v_self)
{
  RPP::QSizeF self = v_self;
  self.check_frozen();
  RPP::QSizeF v_scaled = cSizeF_scaled(argc, argv, v_self);
  // then assign it
  *self = *v_scaled;
  return v_self;
}

static VALUE
cSizeF_transposed(VALUE v_self)
{
  return RPP::QSizeF(RPP::QSizeF(v_self)->transposed());
}

static VALUE
cSizeF_transpose(VALUE v_self)
{
  const RPP::QSizeF self = v_self;
  self.check_frozen();
  self->transpose();
  return v_self;
}

static VALUE
cSizeF_toSize(VALUE v_self)
{
  const RPP::QSizeF self = v_self;
  return RPP::QSize(self->toSize());
}

static VALUE
cSizeF_boundedTo(VALUE v_self, VALUE v_other)
{
  double width, height;
  if (argcv2wh(1, &v_other, width, height))
    return RPP::QSizeF(RPP::QSizeF(v_self)->boundedTo(QSizeF(width, height)));
  return RPP::QSizeF(QSizeF());
}

static VALUE
cSizeF_expandedTo(VALUE v_self, VALUE v_other)
{
  double width, height;
  if (argcv2wh(1, &v_other, width, height))
    return RPP::QSizeF(RPP::QSizeF(v_self)->expandedTo(QSizeF(width, height)));
  return RPP::QSizeF(QSizeF());
}

// CONTEXT: init_graphicsitem()
void 
init_size(RPP::Module mQt)
{
#define DEF_SZ_METHODS(cls) \
  cls.define_alloc_func(cls##_alloc) \
     .define_private_method("initialize", cls##_initialize) \
     .define_method("width", cls##_width) \
     .define_method("height", cls##_height) \
     .define_method("width=", cls##_width_set) \
     .define_method("height=", cls##_height_set) \
     .define_method("empty?", cls##_empty_p) \
     .define_method("valid?", cls##_valid_p) \
     .define_method("null?", cls##_null_p) \
     .define_method("assign", cls##_assign) \
     .define_method("+", cls##_add) \
     .define_method("-", cls##_substract) \
     .define_method("*", cls##_multiply) \
     .define_method("/", cls##_divide) \
     .define_method("==", cls##_equal_p) \
     .define_method("!=", cls##_unequal_p) \
     .define_method("to_a", cls##_to_a) \
     .define_method("to_s", cls##_to_s) \
     .define_method("scale", cls##_scaled) \
     .define_method("scale!", cls##_scale) \
     .define_method("transpose", cls##_transposed) \
     .define_method("transpose!", cls##_transpose) \
     .define_method("|", cls##_expandedTo) \
     .define_method("&", cls##_boundedTo) \
     .define_alias("w", "width") \
     .define_alias("h", "height") \
     .define_alias("w=", "width=") \
     .define_alias("h=", "height=") \
     .define_alias("equal?", "==") \
     .define_alias("inspect", "to_s") \
 
  cSize = mQt.define_class("Size", rb_cObject);
  DEF_SZ_METHODS(cSize);

  cSizeF = mQt.define_class("SizeF", rb_cObject);
  DEF_SZ_METHODS(cSizeF);
  cSizeF.define_method("toSize", cSizeF_toSize);
} // init_size

} // namespace R_Qt 

namespace RPP {

QSize::QSize(int argc, VALUE *argv): QSize(new ::QSize)
{
  R_Qt::cSize_initialize(argc, argv, V);
}

QSizeF::QSizeF(int argc, VALUE *argv): QSizeF(new ::QSizeF)
{
  R_Qt::cSizeF_initialize(argc, argv, V);
}

} // namespace RPP 
