
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

//#define TRACE

#pragma implementation
#include "brush.h"
#include "graphicsitem.h"
#include "object.h"
#include "ruby++/dataobject.h"
#include "ruby++/array.h"
#include "ruby++/hash.h"
#include <assert.h>
#include <QtGui/QBrush>
#include <QtWidgets/QGraphicsScene>

namespace RPP {
class QBrush: public DataObject< ::QBrush >
{
private:
  typedef DataObject< ::QBrush > inherited;
public:
  QBrush(VALUE v_o): inherited(v_o)
    {
#if defined(DEBUG)
      if (!rb_obj_is_kind_of(v_o, R_Qt::cBrush))
	rb_raise(rb_eTypeError, "SERIOUS PROGRAMMING ERROR: very bad cast to QBrush");
#endif // DEBUG
      GET_STRUCT(::QBrush, o);
      this->setWrapped(o);
    }
  QBrush(::QBrush *brush): inherited(Data_Wrap_Struct(R_Qt::cBrush, 0, R_Qt::cBrush_free, brush)) {}
  QBrush(const ::QBrush &brush): 
    inherited(Data_Wrap_Struct(R_Qt::cBrush, 0, R_Qt::cBrush_free, new ::QBrush(brush)))
    {
    }
  void operator=(VALUE v) { V = v; }
  // CRAZY  void operator=(const RPP::QBrush &other) { V = other.value(); }
}; // class RPP::QBrush

class QColor: public DataObject< ::QColor >
{
private:
  typedef DataObject< ::QColor > inherited;
public:
  QColor(VALUE v_o): inherited(v_o)
    {
#if defined(DEBUG)
      if (!rb_obj_is_kind_of(v_o, R_Qt::cColor))
	rb_raise(rb_eTypeError, "SERIOUS PROGRAMMING ERROR: very bad cast to QColor");
#endif // DEBUG
      GET_STRUCT(::QColor, o);
      this->setWrapped(o);
    }
  QColor(::QColor *color): inherited(Data_Wrap_Struct(R_Qt::cColor, 0, R_Qt::cColor_free, color)) {}
  QColor(const ::QColor &color): 
    inherited(Data_Wrap_Struct(R_Qt::cColor, 0, R_Qt::cColor_free, new ::QColor(color)))
    {
    }
}; // class RPP::QColor

} // namespace RPP

namespace R_Qt {

RPP::Class 
cBrush,
cColor, 
cDynamicColor;

void
cBrush_free(QBrush *brush)
{
  traqt1("delete QBrush %p", brush);
  delete brush;
}

static void
reattach_brush(RPP::QBrush self)
{
  trace("reattach_brush");
  const RPP::Object v_parent = self.iv("@parent");
  track1("parent = %s", v_parent);
  if (v_parent.is_kind_of(cGraphicsScene))
    {
      trace("setBackgroundBrush");
      const RPP::QObject<QGraphicsScene> parent(v_parent);
      parent->setBackgroundBrush(self);
    }
  else
    {
      RQTDECLARE_GI(QAbstractGraphicsShapeItem, parent);
      trace2("parent.class=%s, parent=%p", rb_obj_classname(v_parent), parent);
      trace3("color_set, call setBrush %s (QBrush:%p) on parent %s", TO_CSTR(v_self), self, 
	     TO_CSTR(v_parent));
      trace2("parent.class=%s, parent=%p", rb_obj_classname(v_parent), parent);
      traqt1("%p::setBrush", parent);
      parent->setBrush(*self);
    }
  trace("reattach_brush OK");
} // reattach_brush

static void
anything_else(QBrush *self, VALUE v_args)
{
  track1("Anything else: %s", v_args);
  RPP::QColor color = cColor.new_instance(v_args);
  traqt("QBrush()");
  *self = QBrush(*color);
} // anything_else

static VALUE
cBrush_initialize(int argc, VALUE *argv, VALUE v_self)
{
  trace1("cBrush_initialize, argc = %d", argc);
  RPP::QBrush self = v_self;
  RPP::Object args, parent;
  if (argc == 1)
    {
      args = argv[0];  // this can be a T_ARRAY...
      if (args.is_kind_of(cGraphicsItem) || args.is_kind_of(cGraphicsScene))
	{
	  trace("located parent as argv0");
	  parent = args;
	  args = Qnil;
	}
    }
  else // argc > 1
    {
      const RPP::Object arg0 = argv[0];
      if (arg0.is_kind_of(cGraphicsItem) || arg0.is_kind_of(cGraphicsScene))
	{
	  trace("located parent as argv0, shift");
	  parent = argv[0];
	  argc--, argv++;
	} 
      if (argc == 1)
	args = argv[0];
      else
	args = RPP::Array(argc, argv);
    }
  if (!parent.isNil())
    {
      track2("%s created with parent %s", self, parent);
      self.call("parent=", parent);
    }
  switch (args.type())
    {
    case T_DATA:
	if (args.is_kind_of(cBrush))
	  {
	    track1("Brush %s", args);
	    *self = RPP::QBrush(args);
	  }
	else if (args.is_kind_of(cColor))
	  {
	    track1("Color %s", args);
	    traqt("QBrush()");
	    *self = QBrush(*RPP::QColor(args));
	  }
	else
	    anything_else(self, args);
	break;
    case T_FALSE:
	trace("false");
	traqt("QBrush(NoBrush)");
	*self = QBrush(Qt::NoBrush);
	break;
    case T_SYMBOL:
      {
	const ID id = RPP::Symbol(args, RPP::Symbol::Unsafe).to_id();	// FIXME. Need Id class I guess
	if (id == rb_intern("none")
	    || id == rb_intern("nobrush")
	    || id == rb_intern("no_brush"))
	  {
	    trace(":none, :nobrush, :no_brush");
	    traqt("QBrush(NoBrush)");
	    *self = QBrush(Qt::NoBrush);
	  }
	else
	    anything_else(self, args);
	break;
      }
    case T_NIL:
	if (rb_block_given_p())	// hm....
	  {
	    trace("&block");
	    self.instance_eval();
	  }
	else
	    anything_else(self, args);
	break;
    case T_HASH:
	track1("Hash %s", args);
	self.call("setupQuickyhash", args); 
	break;
    case T_STRING:
      {
	const char * const s = RPP::String(args);
	if (strncmp(s, "file://", 7) == 0)
	  rb_raise(rb_eNotImpError, "loading pixmaps for brushes");
	track1("String %s", args);
	const RPP::QColor color = cColor.new_instance(args);
	trace3("v_color=%d,%d,%d", color->red(), color->green(), color->blue());
	trace1("QColorptr = %p", color);
	traqt("QBrush(QColor)");
	*self = QBrush(*color);
	trace3("self.color=%d,%d,%d", self->color().red(), self->color().green(),
	       self->color().blue());
	trace1("self.style=%d", self->style());
	break;
      }
    case T_ARRAY:
      {
	track1("Array %s", args);
	traqt("QBrush(QColor)");
	*self = QBrush(*RPP::QColor(cColor.new_instance(RPP::Array(args, RPP::Array::Unsafe))));
	break;
      }
    default:
	anything_else(self, args);
	break;
    } // switch TYPE
  // Late assignment, because model_init_path may have changed the color.
  // Even though it should already have called setBrush in that case.
  if (!parent.isNil())
    reattach_brush(self);
  trace("cBrush_initialize OK");
  return Qnil;
} // cBrush_initialize

R_QT_DEF_ALLOCATOR_BASE1(Brush)

static VALUE
cBrush_parent_set(VALUE v_self, VALUE v_parent)
{
  track2("%s::parent_set(%s)", v_self, v_parent);
  const RPP::Object self = v_self;
  const RPP::Object parent = v_parent;
  self.check_frozen();
  const RPP::Object old_parent = self.iv("@parent");
  if (!old_parent.isNil())
    {
      track1("Removing old parent %s", old_parent);
      old_parent.call("brush=", Qnil);
    }
  self.iv_set("@parent", parent);
  if (!parent.isNil())
    {
      track2("calling %s.brush= %s", parent, self);
      parent.call("brush=", self);
    }
  return v_parent;
} // cBrush_parent_set

static VALUE
cBrush_apply_model(VALUE v_self, VALUE v_data)
{
  const RPP::Object self = v_self;
  return self.call("apply_dynamic_setter", RPP::Symbol("color"), v_data);
} // cBrush_apply_model

static VALUE
cBrush_color_set(VALUE v_self, VALUE v_data)
{
  track2("%s::color_set(%s)", v_self, v_data);
  RPP::QBrush self = v_self;
  self.check_frozen();
  const RPP::QColor color = cColor.new_instance(v_data);
  traqt1("%p::setColor", self);
  trace4("color_set: v_self=%s, color=(%d,%d,%d)", INSPECT(v_self), color->red(), color->green(), color->blue());
  // INCORRECT self->setColor(*color);
  *self = QBrush(*color);
  trace5("self=%p, brush.color=(%d,%d,%d,%d)", self,
         self->color().red(), self->color().green(), self->color().blue(), self->color().alpha());
  reattach_brush(self);
  return v_data;
} // cBrush_color_set

static VALUE
cBrush_color_get(VALUE v_self)
{
  track1("%s::color_get()", v_self);
  return RPP::QColor(RPP::QBrush(v_self)->color());
} // cBrush_color_get

void 
init_brush(VALUE /*bogo*/)
{
  trace("init_brush");
  cBrush = mQt.define_class("Brush", cNoQtControl);
  cBrush.define_alloc_func(cBrush_alloc)
	.define_private_method("initialize", cBrush_initialize)
	.define_method("parent=", cBrush_parent_set)
	.define_method("apply_model", cBrush_apply_model)
	.define_method("color=", cBrush_color_set)
	.define_method("color_get", cBrush_color_get)
	;
  RPP::Dictionary hash;
  hash["klass"] = cDynamicColor;
  hash["require"] = "dynamic_color";
  cBrush.call("attr_dynamic", cColor, RPP::Symbol("color"), hash);
} // init_brush

R_QT_DEF_ALLOCATOR_BASE1(Color)

static Qt::GlobalColor
cColor_sym2color(VALUE v_self, VALUE v_sym)
{
  track2("%s::sym2color(%s)", v_self, v_sym);
  const RPP::Object self = v_self;
  RPP::Dictionary colors(self.iv("@color"), RPP::Dictionary::Unsafe);
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
  trace("cColor_initialize");
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
	  return self.instance_eval();
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
	const RPP::Array ary(colorsym, RPP::Array::Unsafe);
	return cColor_initialize(ary.length(), ary.ptr(), self);
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

void 
init_color(VALUE /*bogo*/)
{
  trace("init_color");
  cColor = mQt.define_class("Color", cNoQtControl);
  cColor.define_alloc_func(cColor_alloc)
        .define_private_method("initialize", cColor_initialize)
	COMPS
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
	.define_alias("hue=", "hsvHue=")
	.define_alias("saturation=", "hsvSaturation=")
	.define_alias("hue_get", "hsvHue_get")
	;
// According to Qt manual     hsvHue does not convert color, but hue() does, even if it is a getter.
// Or maybe they both do.

#undef INT_COMP
#undef INT_COMP_RO
#undef FLOAT_COMP
#undef FLOAT_COMP_RO

#define INT_COMP(comp, Comp) cColor.call("attr_dynamic", rb_cFixnum, RPP::Symbol(#comp));
#define INT_COMP_RO INT_COMP
#define FLOAT_COMP(comp, Comp) cColor.call("attr_dynamic", rb_cFloat, RPP::Symbol(#comp "F"));
#define FLOAT_COMP_RO FLOAT_COMP
  COMPS
  cColor.define_alias("saturation_get", "hsvSaturation_get")
	.define_alias("hue", "hsvHue")
	.define_alias("saturation", "hsvSaturation")
	;
  cDynamicColor = mQt.define_class("DynamicColor", cDynamicAttribute);
  trace("DONE init_color");
}

} // namespace R_Qt 
