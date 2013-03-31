
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

//#define TRACE

#pragma implementation
#include "color.h"
#include "brush.h"
#include "object.h"
#include "urqtCore/stringlist.h"
#include "ruby++/dataobject.h"
#include "ruby++/array.h"
#include "ruby++/hash.h"
#include "ruby++/bool.h"

namespace R_Qt {

RPP::Class 
cColor, 
cDynamicColor;

R_QT_DEF_ALLOCATOR_BASE1(Color)

static Qt::GlobalColor
cColor_sym2color(VALUE v_self, VALUE v_sym)
{
  track2("%s::sym2color(%s)", v_self, v_sym);
  const RPP::Object self = v_self;
  RPP::Dictionary colors(self.iv("@color"), RPP::VERYUNSAFE);
  if (!colors.isHash())
    {
      trace("setup @color hash");
      colors = RPP::Dictionary();
      self.iv_set("@color", colors);
#define QTCOLOR_DO(sym) \
      colors[#sym] = (int)Qt::sym
      QTCOLOR_DO(white);
      QTCOLOR_DO(black);
      QTCOLOR_DO(yellow);
      QTCOLOR_DO(blue);
      QTCOLOR_DO(green);
      QTCOLOR_DO(red);
      QTCOLOR_DO(darkYellow);
      QTCOLOR_DO(darkBlue);
      QTCOLOR_DO(darkGreen);
      QTCOLOR_DO(darkRed);
      QTCOLOR_DO(cyan);
      QTCOLOR_DO(darkCyan);
      QTCOLOR_DO(magenta);
      QTCOLOR_DO(darkMagenta);
      QTCOLOR_DO(gray);
      QTCOLOR_DO(darkGray);
      QTCOLOR_DO(lightGray);
      QTCOLOR_DO(transparent);
    }
  track1("Check_Type(%s, T_HASH)", colors);
  return Qt::GlobalColor(RPP::Fixnum(colors[v_sym]).to_i());
} // cColor_sym2color

// where hex is in range '0'..'9' or 'A'..'F'
static inline int
hex2int(int hex)
{
  return hex - (hex >= 'A' ? 'A' - 10 : '0');
} // hex2int

/** :call-seq:
    Color.new						   # The default color. Let's say: black
    Color.new :white					   # or any other QGlobalColor. These are cached.
    Color.new Color
    Color.new Color, alpha
    Color.new Brush
    Color.new '#rgb'					    # must be hexadecimals, case insensitive
    Color.new '#rrggbb'
    Color.new '#rrrgggbbb'
    Color.new '#rrrrggggbbbb'
    Color.new '#rgba'					    # etc
    Color.new red, green, blue, opaqueness = 255	    # all values must be between 0 and 255
    Color.new gray_value, opaqueness = 255  
    Color.new red, green, blue, opaqueness = 1.0	    # all values must be between 0.0 and 1.0
    Color.new gray_value, opaqueness = 1.0  
    Color.new [array_args]				    # splatted
    Color.new Hash					    # same as Control constructor
    Color.new { initblock }				    # same as Control constructor

    Colors have neither parents nor children
 */
static VALUE
cColor_initialize(int argc, VALUE *argv, VALUE v_self)
{
  trace1("cColor_initialize, argc=%d", argc);
  RPP::QColor self = v_self;
  VALUE v_colorsym, v_g, v_b, v_a;
  rb_scan_args(argc, argv, "04", &v_colorsym, &v_g, &v_b, &v_a);
  track4("cColor_initialize(%s, %s, %s, %s)", v_colorsym, v_g, v_b, v_a);
  const RPP::Object colorsym = v_colorsym;
  const RPP::Object g = v_g, b = v_b, a = v_a;
  switch (colorsym.type())
    {
    case T_HASH:
	return self.call("setupQuickyhash", colorsym);
    case T_NIL:
	if (rb_block_given_p())
	  {
	    trace("instance_eval on block");
	    return self.instance_eval();
	  }
	trace("default color assign");
	*self = QColor();
	return Qnil;
    case T_DATA:
	if (colorsym.is_kind_of(cColor)) 
	  {
	    trace("when Color");
	    if (!g.isNil()) colorsym.call("alpha=", g);
	    *self = *RPP::QColor(colorsym);
	    return Qnil;
	  }
	if (colorsym.is_kind_of(cBrush))
	  {
	    trace("when Brush");
	    *self = *RPP::QColor(colorsym.call("color"));
	    return Qnil;
	  }
	break;
    case T_STRING:
      {
	trace("when String");
	const char *s = RPP::String(colorsym);
	if (*s == '#')
	  {
	    const size_t l = strlen(s);
	    char t[l + 1];
	    strcpy(t, s);
	    s = t;
	    for (char *u = t; *u; u++)
	      *u = toupper(*u);
	    switch (l)
	      {
	      case 5:
		{
		  // 17 * 0xf = 17 * 15 = 255. How nice.
		  const int alpha = hex2int(t[4]) * 17;
		  t[4] = 0;
		  QColor * const r = new QColor(t);
		  r->setAlpha(alpha);
		  *self = *r;
		  return Qnil;
		}
	      case 9:
		{
		  const int alpha = hex2int(t[7]) * 16 + hex2int(t[8]);
		  t[7] = 0;
		  QColor * const r = new QColor(t);
		  r->setAlpha(alpha);
		  *self = *r;
		  return Qnil;
		}
	      case 13:
		{
		  const int alpha = hex2int(t[10]) * 256 + hex2int(t[11]) * 16 + hex2int(t[12]);
		  t[10] = 0;
		  QColor * const r = new QColor(t);
		  r->setAlphaF(alpha / 4096.0);
		  *self = *r;
		  return Qnil;
		}
	      case 17:
		{
		  const int alpha = hex2int(t[13]) * 65536 + hex2int(t[14]) * 256 
				    + hex2int(t[15]) * 16 + hex2int(t[16]);
		  t[13] = 0;
		  QColor * const r = new QColor(t);
		  r->setAlphaF(alpha / 65536.0);
		  *self = *r;
		  return Qnil;
		}
	      default:
		  break;
	      } // switch strlen
	    return cColorWrap(new QColor(s));
	  } // strings starting with '#'
	QColor * const r = new QColor(s);
	trace5("ordinary string '%s' -> r:%d, g:%d, b: %d, a:%d", s, r->red(), r->green(), 
	       r->blue(), r->alpha());
	trace1("QColorptr = %p", r);
	*self = *r;
	return Qnil;
      }
    case T_ARRAY:
      {
	trace("when Array");
	const RPP::Array ary(colorsym, RPP::VERYUNSAFE);
	return cColor_initialize(ary.len(), ary.ptr(), self);
      }
    case T_FIXNUM:
      {
	trace("when Fixnum");
	if (b.isNil())
	  {
	    const int gray = colorsym.to_i();
	    const int alpha = g.isNil() ? 255 : g.to_i();
	    *self = QColor(gray, gray, gray, alpha);
	    return Qnil;
	  }
	const int alpha = a.isNil() ? 255 : a.to_i();
	*self = QColor(colorsym.to_i(), g.to_i(), b.to_i(), alpha);
	return Qnil;
      }
    case T_FLOAT:
      {
	trace("when Float");
	if (b.isNil())
	  {
	    const double gray = colorsym.to_f();
	    const double alpha = g.isNil() ? 1.0 : g.to_i();
	    *self = QColor(gray, gray, gray, alpha);
	    return Qnil;
	  }
	const double alpha = a.isNil() ? 1.0 : a.to_i();
	*self = QColor(colorsym.to_f(), g.to_f(), b.to_f(), alpha);
	return Qnil;
      }
    case T_SYMBOL:
      {
	trace("when Symbol");
	const Qt::GlobalColor gc = cColor_sym2color(cColor, colorsym);
	*self = QColor(gc);
	return Qnil;
      }
    } // switch TYPE colorsym
  rb_raise(rb_eArgError, "invalid color %s, %s, %s, %s", colorsym.inspect(), g.inspect(),
	   b.inspect(), a.inspect());
} // cColor_initialize

void 
cColor_free(QColor *color)
{
  traqt1("delete QColor %p", color);
  delete color;
} // cColor_free

#define COMP(comp, Comp) INT_COMP(comp, Comp) FLOAT_COMP(comp, Comp)
#define COMP_RO(comp, Comp) INT_COMP_RO(comp, Comp) FLOAT_COMP_RO(comp, Comp)
#define COMPS \
	COMP(alpha, Alpha) \
	COMP(blue, Blue) \
	COMP(green, Green) \
	COMP(red, Red) \
	COMP_RO(black, Black) \
	COMP_RO(cyan, Cyan) \
	COMP_RO(hslHue, HslHue) \
	COMP_RO(hslSaturation, HslSaturation) \
	COMP_RO(hsvHue, HsvHue) \
	COMP_RO(hsvSaturation, HsvSaturation) \
	COMP_RO(lightness, Lightness) \
	COMP_RO(magenta, Magenta) \
	COMP_RO(yellow, Yellow) \
	COMP_RO(value, Value) \

#define TYPE_COMP_RO(tp, comp, Comp) \
static VALUE \
cColor_##comp##_get(VALUE v_self) \
{ \
  trace("QColor::" #comp "_get"); \
  return RPP::tp(RPP::QColor(v_self)->comp()); \
} 

#define TYPE_COMP(tp, comp, Comp) \
TYPE_COMP_RO(tp, comp, Comp) \
\
static VALUE \
cColor_##comp##_set(VALUE v_self, VALUE v_comp) \
{ \
  RPP::QColor(v_self)->set##Comp(RPP::tp(v_comp)); \
  return v_comp; \
}

#define INT_COMP_RO(comp, Comp) TYPE_COMP_RO(Fixnum, comp, Comp)
#define INT_COMP(comp, Comp) TYPE_COMP(Fixnum, comp, Comp)
#define FLOAT_COMP_RO(comp, Comp) TYPE_COMP_RO(Float, comp##F, Comp##F)
#define FLOAT_COMP(comp, Comp) TYPE_COMP(Float, comp##F, Comp##F)

COMPS

/* Now we need some handmade stuff
 */
#define TP_CMYK_SETTER(ctp, rpptp, comp, suffix) \
static VALUE \
cColor_##comp##suffix##_set(VALUE v_self, VALUE v_comp) \
{ \
  const RPP::QColor self = v_self; \
  ctp cyan##suffix, magenta##suffix, yellow##suffix, black##suffix, alpha; \
  self->getCmyk##suffix(&cyan##suffix, &magenta##suffix, &yellow##suffix, \
			&black##suffix, &alpha); \
  comp##suffix = RPP::rpptp(v_comp); \
  self->setCmyk##suffix(cyan##suffix, magenta##suffix, yellow##suffix, \
			black##suffix, alpha); \
  return v_comp; \
}

#define INT_CMYK_SETTER(comp) TP_CMYK_SETTER(int, Fixnum, comp, )
#define FLOAT_CMYK_SETTER(comp) TP_CMYK_SETTER(double, Float, comp, F)
#define CMYK_SETTER(comp) INT_CMYK_SETTER(comp) FLOAT_CMYK_SETTER(comp)

CMYK_SETTER(black)
CMYK_SETTER(cyan)
CMYK_SETTER(magenta)
CMYK_SETTER(yellow)

#define TP_HSL_SETTER(hsl, ctp, rpptp, comp, Comp, suffix) \
static VALUE \
cColor_##hsl##Comp##suffix##_set(VALUE v_self, VALUE v_comp) \
{ \
  const RPP::QColor self = v_self; \
  ctp hue##suffix, saturation##suffix, lightness##suffix, alpha; \
  self->getHsl##suffix(&hue##suffix, &saturation##suffix, &lightness##suffix, \
		       &alpha); \
  comp##suffix = RPP::rpptp(v_comp); \
  self->setHsl##suffix(hue##suffix, saturation##suffix, lightness##suffix, alpha); \
  return v_comp; \
}

#define INT_HSL_SETTER(comp, Comp, hsl) TP_HSL_SETTER(hsl, int, Fixnum, comp, Comp, )
#define FLOAT_HSL_SETTER(comp, Comp, hsl) TP_HSL_SETTER(hsl, double, Float, comp, Comp, F)
#define HSL_SETTER(comp, Comp, hsl) INT_HSL_SETTER(comp, Comp, hsl) FLOAT_HSL_SETTER(comp, Comp, hsl)

HSL_SETTER(hue, Hue, hsl)
HSL_SETTER(saturation, Saturation, hsl)
HSL_SETTER(lightness, lightness, )

#define TP_HSV_SETTER(hsv, ctp, rpptp, comp, Comp, suffix) \
static VALUE \
cColor_##hsv##Comp##suffix##_set(VALUE v_self, VALUE v_comp) \
{ \
  const RPP::QColor self = v_self; \
  ctp hue##suffix, saturation##suffix, value##suffix, alpha; \
  self->getHsv##suffix(&hue##suffix, &saturation##suffix, &value##suffix, \
		       &alpha); \
  comp##suffix = RPP::rpptp(v_comp); \
  self->setHsv##suffix(hue##suffix, saturation##suffix, value##suffix, alpha); \
  return v_comp; \
}

#define INT_HSV_SETTER(comp, Comp, hsv) TP_HSV_SETTER(hsv, int, Fixnum, comp, Comp, )
#define FLOAT_HSV_SETTER(comp, Comp, hsv) TP_HSV_SETTER(hsv, double, Float, comp, Comp, F)
#define HSV_SETTER(comp, Comp, hsv) INT_HSV_SETTER(comp, Comp, hsv) FLOAT_HSV_SETTER(comp, Comp, hsv)

HSV_SETTER(hue, Hue, hsv)
HSV_SETTER(saturation, Saturation, hsv)
HSV_SETTER(value, value, )

#undef INT_COMP
#undef INT_COMP_RO
#undef FLOAT_COMP
#undef FLOAT_COMP_RO

#define INT_COMP(comp, Comp) \
    .define_method(#comp "_get", cColor_##comp##_get) \
    .define_method(#comp "=", cColor_##comp##_set) \

#define FLOAT_COMP(comp, Comp) \
    .define_method(#comp "F_get", cColor_##comp##F_get) \
    .define_method(#comp "F=", cColor_##comp##F_set) \

#define INT_COMP_RO INT_COMP
#define FLOAT_COMP_RO FLOAT_COMP

static VALUE
cColor_colorNames(VALUE /*cColor*/)
{
  return RPP::QStringList(QColor::colorNames());
}

static VALUE
cColor_isValidColor(VALUE /*cColor*/)
{
  return RPP::Bool(QColor::isValidColor(RPP::String(cColor).to_s()));
}

void 
init_color(RPP::Module qt)
{
  trace("init_color");
  cColor = qt.define_class("Color", cNoQtControl);
  cColor.define_alloc_func(cColor_alloc)
        .define_private_method("initialize", cColor_initialize)
	COMPS
	.define_function("colorNames", cColor_colorNames)
	.define_function("validColor?", cColor_isValidColor)
	/* MAYBE LATER
	.define_method("convertTo", cColor_convertTo)
	.define_method("darker", cColor_darker)
	.define_method("lighter", cColor_lighter)
	.define_method("cmyk_get", cColor_cmyk_get)
	.define_method("cmykF_get", cColor_cmykF_get)
	.define_method("hsl_get", cColor_hsl_get)
	.define_method("hslF_get", cColor_hslF_get)
	.define_method("hsv_get", cColor_hsv_get)
	.define_method("hsvF_get", cColor_hsvF_get)
	*/
	;
// According to Qt manual     hsvHue does not convert color, but hue() does, even if it is a getter.
// Or maybe they both do.

  cDynamicColor = mQt.define_class("DynamicColor", cDynamicAttribute);
  trace("DONE init_color");
} // init_color

} // namespace R_Qt 
