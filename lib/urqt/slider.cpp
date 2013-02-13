
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

//#define TRACE

#include <QtWidgets/QSlider>
#include "application.h"
#include "ruby++/numeric.h"
#include "ruby++/hash.h"
#include "ruby++/range.h"
#include "ruby++/array.h"

namespace R_Qt {

R_QT_DEF_ALLOCATOR(Slider)

RPP::Class
cAbstractSlider, cSlider;

static const double 
FloatModeFactor = 10000.0;

static VALUE
cAbstractSlider_initialize(int argc, VALUE *argv, VALUE v_self)
{
  trace("cAbstractSlider_initialize");
  rb_call_super(argc, argv);
  RPP::QObject<QAbstractSlider> self = v_self;
  self.iv_set("@floatmode", true);
  self->setRange(0, FloatModeFactor + 0.5);
  return Qnil;
}

static VALUE
cAbstractSlider_value_set(VALUE v_self, VALUE v_val)
{
  track2("%s::value=(%s)", v_self, v_val);
  RPP::QObject<QAbstractSlider> self = v_self;
  self.check_frozen();
  self->setValue(RPP::Fixnum(v_val));
  return v_val;
}

static VALUE
cAbstractSlider_value_get(VALUE v_self)
{
  track1("%s::value_get()", v_self);
  RPP::QObject<QAbstractSlider> self = v_self;
  return RPP::Fixnum(self->value());
}

static VALUE
cAbstractSlider_orientation_set(VALUE v_self, VALUE v_or)
{
  RPP::QObject<QAbstractSlider> self = v_self;
  self.check_frozen();
  RPP::Dictionary syms(cAbstractSlider.cv("@@orientations"), RPP::Hash::Unsafe);
  if (!syms.isHash())
    {
      syms = RPP::Dictionary();
      cAbstractSlider.cv_set("@@orientations", syms);
#define QTORIENTATION_DO(sym, qtor) \
      syms[#sym] = int(Qt::qtor);
#define QTORIENTATIONS \
      QTORIENTATION_DO(horizontal, Horizontal) \
      QTORIENTATION_DO(vertical, Vertical)
      QTORIENTATIONS
      QTORIENTATION_DO(default, Vertical);
#undef QTORIENTATION_DO
    }
  const RPP::Fixnum orientation = syms[v_or];
  self->setOrientation(Qt::Orientation(orientation.to_i()));
  return v_or;
}

static VALUE
cAbstractSlider_orientation_get(VALUE v_self)
{
  RPP::QObject<QAbstractSlider> self = v_self;
  switch (self->orientation())
    {
#define QTORIENTATION_DO(sym, qtor) \
      case Qt::qtor: return RPP::Symbol(#sym);
      QTORIENTATIONS
      default: break;
    }
  rb_raise(rb_eRuntimeError, "Unhandled orientation %d", self->orientation());
}

/** :call-seq:
 *	slider.range = float, float
 *	slider.range = int, int
 *	slider.range = range
 *	slider.range = float-tuple
 *	slider.range = int-tuple
 */
static VALUE
cAbstractSlider_range_set(int argc, VALUE *argv, VALUE v_self)
{
  track1("%s::range=...", v_self);
  RPP::QObject<QAbstractSlider> self = v_self;
  VALUE v_from, v_to;
  rb_scan_args(argc, argv, "11", &v_from, &v_to);
  bool floatmode = true;
  double d_from, d_to; // if floatmode
  int i_from, i_to; // unless floatmode
  if (NIL_P(v_to))
    {
      trace("No 'to', expect arg1 to be Range or Array");
      RPP::Range range(v_from, RPP::Range::Unsafe);
      if (range.isRange())
	{
	  trace("isRange");
	  v_from = range.min(), v_to = range.max();
	}
      else
	{
	  trace("isArray(?)");
	  const RPP::Array ary = v_from;
	  v_from = ary[0], v_to = ary[1];
	}
    }
  if (TYPE(v_to) == T_FLOAT)
    {
      trace("Floatmode");
      d_from = RPP::Float(v_from);
      d_to = RPP::Float(v_to);
      d_from = FloatModeFactor * d_from + 0.5;
      d_to = FloatModeFactor * d_to + 0.5;
      if (d_from > d_to
	  || d_from < INT_MIN + 1
	  || d_to > INT_MAX - 1)
	rb_raise(rb_eArgError, "Invalid range [%f..%f]", RPP::Float(v_from).to_f(), 
		 RPP::Float(v_to).to_f());
      trace2("setRange(%d, %d)", int(d_from), int(d_to));
      self->setRange(d_from, d_to);
    }
  else
    {
      trace("Intmode");
      floatmode = false;
      i_from = RPP::Fixnum(v_from), i_to = RPP::Fixnum(v_to);
      if (i_from > i_to)
	rb_raise(rb_eArgError, "Invalid range [%d..%d]", i_from, i_to);
      trace2("setRange(%d, %d)", i_from, i_to);
      self->setRange(i_from, i_to);
    }
  self.iv_set("@floatmode", floatmode); 
  return Qnil;
}

#define MINMAXER(imum) \
static VALUE \
cAbstractSlider_##imum##imum_set(VALUE v_self, VALUE v_imum) \
{ \
  RPP::QObject<QAbstractSlider> self = v_self; \
  self.check_frozen(); \
  self->setMinimum(RPP::Fixnum(v_imum)); \
  return v_imum; \
} \
\
static VALUE \
cAbstractSlider_##imum##imum_get(VALUE v_self) \
{ \
  RPP::QObject<QAbstractSlider> self = v_self; \
  return RPP::Fixnum(self->minimum()); \
}

#define MINMAXERF(imum) \
static VALUE \
cAbstractSlider_##imum##imumF_set(VALUE v_self, VALUE v_imum) \
{ \
  RPP::QObject<QAbstractSlider> self = v_self; \
  self.check_frozen(); \
  const double d = RPP::Float(v_imum); \
  const double df = FloatModeFactor * d + 0.5; \
  if (df < INT_MIN + 1 || df > INT_MAX - 1) \
    rb_raise(rb_eArgError, "Invalid " #imum "imum %f", d); \
  self->setMinimum(df); \
  return v_imum; \
} \
\
static VALUE \
cAbstractSlider_##imum##imumF_get(VALUE v_self) \
{ \
  RPP::QObject<QAbstractSlider> self = v_self; \
  return RPP::Float(double(self->minimum()) / FloatModeFactor); \
}

MINMAXER(min)
MINMAXER(max)
MINMAXERF(min)
MINMAXERF(max)

static void
init_abstractSlider(RPP::Class cWidget)
{
  cAbstractSlider = mQt.define_class("AbstractSlider", cWidget);
  cAbstractSlider.define_method("value=", cAbstractSlider_value_set)
		 .define_method("value_get", cAbstractSlider_value_get);
  cAbstractSlider.call("attr_dynamic", rb_cFixnum, RPP::Symbol("value"));
  cAbstractSlider.define_method("range=", cAbstractSlider_range_set)
		 .define_alias("range", "range=")
		 .define_private_method("initialize", cAbstractSlider_initialize)
		 .define_method("minimum=", cAbstractSlider_minimum_set)
		 .define_method("minimum_get", cAbstractSlider_minimum_get)
		 .define_method("maximum=", cAbstractSlider_maximum_set)
		 .define_method("maximum_get", cAbstractSlider_maximum_get)
		 .define_method("minimumF=", cAbstractSlider_minimumF_set)
		 .define_method("minimumF_get", cAbstractSlider_minimumF_get)
		 .define_method("maximumF=", cAbstractSlider_maximumF_set)
		 .define_method("maximumF_get", cAbstractSlider_maximumF_get)
		 .define_method("orientation=", cAbstractSlider_orientation_set)
		 .define_method("orientation_get", cAbstractSlider_orientation_get);
  cAbstractSlider.call("attr_dynamic", rb_cSymbol, RPP::Symbol("orientation"));
  cAbstractSlider.call("attr_dynamic", rb_cSymbol, RPP::Symbol("orientation"));
  cAbstractSlider.call("attr_dynamic", rb_cSymbol, RPP::Symbol("orientation"));
  cAbstractSlider.call("attr_dynamic", rb_cInteger, RPP::Symbol("minimum"));
  cAbstractSlider.call("attr_dynamic", rb_cInteger, RPP::Symbol("maximum"));
  cAbstractSlider.call("attr_dynamic", rb_cFloat, RPP::Symbol("minimumF"));
  cAbstractSlider.call("attr_dynamic", rb_cFloat, RPP::Symbol("maximumF"));
}

static VALUE
cSlider_tickPosition_set(VALUE v_self, VALUE v_tickpos)
{
  RPP::QObject<QSlider> self = v_self;
  self.check_frozen();
  RPP::Dictionary syms(cSlider.cv("@@tickpositions"), RPP::Hash::Unsafe);
  if (!syms.isHash())
    {
      syms = RPP::Dictionary();
      cSlider.cv_set("@@tickpositions", syms);
#define QTTICKPOS_DO(sym, qttickpos) \
      syms[#sym] = RPP::Fixnum(QSlider::qttickpos);
#define QTTICKPOSSES \
      QTTICKPOS_DO(noticks, NoTicks) \
      QTTICKPOS_DO(bothsides, TicksBothSides) \
      QTTICKPOS_DO(above, TicksAbove) \
      QTTICKPOS_DO(below, TicksBelow)
      QTTICKPOSSES
      QTTICKPOS_DO(default, NoTicks);
      QTTICKPOS_DO(none, NoTicks);
      /* TRICKY:  the Qt enum contains duplicates.
       */
      QTTICKPOS_DO(left, TicksLeft) 
      QTTICKPOS_DO(right, TicksRight)
#undef QTTICKPOS_DO
    }
  self->setTickPosition(QSlider::TickPosition(RPP::Fixnum(syms[v_tickpos]).to_i()));
  return v_tickpos;
}

/** Note that :left is returned as :above and :right as :below,
 *
 * But they work the same.
 * However :above != :left but QSlider::TicksAbove == QSlider::TicksLeft
 */
static VALUE
cSlider_tickPosition_get(VALUE v_self)
{
  const RPP::QObject<QSlider> self = v_self;
  switch (self->tickPosition())
    {
#define QTTICKPOS_DO(sym, qttickpos) \
      case QSlider::qttickpos: return RPP::Symbol(#sym);
      QTTICKPOSSES
      default: break;
    }
  rb_raise(rb_eRuntimeError, "Unhandled tickposition %d", self->tickPosition());
}

static VALUE
cSlider_tickInterval_set(VALUE v_self, VALUE v_iv)
{
  RPP::QObject<QSlider> self = v_self;
  const RPP::Fixnum iv = v_iv;
  self->setTickInterval(iv);
  return v_iv;
}

static VALUE
cSlider_tickInterval_get(VALUE v_self)
{
  const RPP::QObject<QSlider> self = v_self;
  return RPP::Fixnum(self->tickInterval());
}

void
init_slider(VALUE, VALUE cWidget)
{
  trace("init_slider");
  init_abstractSlider(cWidget);
  /* Sliders provide a value that has some range.
   By default the range is 0.0 .. 1.0.
   
   Changing the slider position has an immediate effect (unless 'tracking false' is used / NYI).
   */
  cSlider = mQt.define_class("Slider", cAbstractSlider);
  cSlider.define_alloc_func(cSlider_alloc)
	 .define_method("tickPosition=", cSlider_tickPosition_set)
         .define_method("tickPosition_get", cSlider_tickPosition_get)
	 .define_method("tickInterval=", cSlider_tickInterval_set)
	 .define_method("tickInterval_get", cSlider_tickInterval_get);
  cSlider.call("attr_dynamic", rb_cSymbol, RPP::Symbol("tickPosition"));
  cSlider.call("attr_dynamic", rb_cFixnum, RPP::Symbol("tickInterval"));
} // init_slider

} // namespace R_Qt {
