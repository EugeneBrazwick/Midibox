
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

//#define TRACE

#pragma implementation
#include "brush.h"
#include "object.h"
#include <assert.h>
#include <QtGui/QBrush>

namespace R_Qt {

VALUE 
cBrush = Qnil, cColor = Qnil;

void
cBrush_free(QBrush *brush)
{
  traqt1("delete QBrush %p", brush);
  delete brush;
}

static VALUE
cBrush_initialize(int argc, VALUE *argv, VALUE v_self)
{
  trace1("cBrush_initialize, argc = %d", argc);
  RQTDECLARE_BRUSH(self);
  VALUE v_args;
  if (argc == 0)
    v_args = Qnil;
  if (argc == 1)
    v_args = argv[0];  // this can be a T_ARRAY...
  else
    v_args = rb_ary_new4(argc, argv);
  switch (TYPE(v_args))
    {
    case T_DATA:
	if (rb_obj_is_kind_of(v_args, cBrush))
	  {
	    track1("Brush %s", v_args);
	    RQTDECLARE_BRUSH(args);
	    *self = *args;
	    return Qnil;
	  }
	else if (rb_obj_is_kind_of(v_args, cColor))
	  {
	    track1("Color %s", v_args);
	    RQTDECLARE_COLOR(args);
	    *self = QBrush(*args);
	    return Qnil;
	  }
	break;
    case T_FALSE:
	trace("false");
	*self = QBrush(Qt::NoBrush);
	return Qnil;
    case T_SYMBOL:
      {
	const ID id = SYM2ID(v_args);
	if (id == rb_intern("none")
	    || id == rb_intern("nobrush")
	    || id == rb_intern("no_brush"))
	  {
	    trace(":none, :nobrush, :no_brush");
	    *self = QBrush(Qt::NoBrush);
	    return Qnil;
	  }
	break;
      }
    case T_NIL:
	if (rb_block_given_p())
	  {
	    trace("&block");
	    return rb_obj_instance_eval(0, 0, v_self);
	  }
	break;
    case T_HASH:
	track1("Hash %s", v_args);
	return rb_funcall(v_self, rb_intern("setupQuickyhash"), 1, v_args); 
    case T_STRING:
      {
	const char * const s = StringValueCStr(v_args);
	if (strncmp(s, "file://", 7) == 0)
	  rb_raise(rb_eNotImpError, "loading pixmaps for brushes");
	track1("String %s", v_args);
	VALUE v_color = rb_class_new_instance(1, &v_args, cColor);
	RQTDECLARE_COLOR(color);
	trace3("v_color=%d,%d,%d", color->red(), color->green(), color->blue());
	trace1("QColorptr = %p", color);
	*self = QBrush(*color);
	trace3("self.color=%d,%d,%d", self->color().red(), self->color().green(),
	       self->color().blue());
	return Qnil;
      }
    case T_ARRAY:
      {
	track1("Array %s", v_args);
	VALUE v_color = rb_class_new_instance(RARRAY_LEN(v_args), RARRAY_PTR(v_args), cColor);
	RQTDECLARE_COLOR(color);
	*self = QBrush(*color);
	return Qnil;
      }
    } // switch TYPE
  track1("Anything else: %s", v_args);
  VALUE v_color = rb_class_new_instance(1, &v_args, cColor);
  RQTDECLARE_COLOR(color);
  *self = QBrush(*color);
  return Qnil;
} // cBrush_initialize

R_QT_DEF_ALLOCATOR_BASE1(Brush)

void 
init_brush(VALUE mQt)
{
  cBrush = rb_define_class_under(mQt, "Brush", cNoQtControl);
  rb_define_alloc_func(cBrush, cBrush_alloc);
  rb_define_const(cBrush, "NoBrush", Qt::NoBrush);
  rb_define_private_method(cBrush, "initialize", RUBY_METHOD_FUNC(cBrush_initialize), -1);
}

static void
cColor_free(QColor *color)
{
  traqt1("delete QColor %p", color);
  delete color;
}

static inline VALUE
cColorWrap(QColor *color)
{
  trace1("cColorWrap(%p)", color);
  return Data_Wrap_Struct(cColor, 0, cColor_free, color);
}

R_QT_DEF_ALLOCATOR_BASE1(Color)

static VALUE
cColor_sym2color(VALUE v_self, VALUE v_sym)
{
  VALUE v_colors = rb_iv_get(v_self, "@color");
  if (NIL_P(v_colors))
    {
      v_colors = rb_hash_new();
      rb_iv_set(v_self, "@color", v_colors);
#define QTCOLOR_DO(sym) \
      rb_hash_aset(v_colors, CSTR2SYM(#sym), INT2NUM(Qt::sym))
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
  Check_Type(T_HASH, v_colors);
  return rb_hash_aref(v_colors, v_sym);
}

// where hex is in range '0'..'9' or 'A'..'F'
static inline int
hex2int(int hex)
{
  return hex - (hex >= 'A' ? 'A' - 10 : '0');
}

/** :call-seq:
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
  RQTDECLARE_COLOR(self);
  VALUE v_colorsym, v_g, v_b, v_a;
  rb_scan_args(argc, argv, "13", &v_colorsym, &v_g, &v_b, &v_a);
  track4("cColor_initialize(%s, %s, %s, %s)", v_colorsym, v_g, v_b, v_a);
  switch (TYPE(v_colorsym))
    {
    case T_HASH:
	return rb_funcall(v_self, rb_intern("setupQuickyhash"), 1, v_colorsym);
    case T_NIL:
	if (rb_block_given_p())
	  return rb_obj_instance_eval(0, 0, v_self);
	break;
    case T_DATA:
	if (rb_obj_is_kind_of(v_colorsym, cColor)) 
	  {
	    trace("when Color");
	    if (!NIL_P(v_g))
	      rb_funcall(v_colorsym, rb_intern("alpha="), 1, v_g);
	    RQTDECLARE_COLOR(colorsym);
	    *self = *colorsym;
	    return Qnil;
	  }
	if (rb_obj_is_kind_of(v_colorsym, cBrush))
	  {
	    trace("when Brush");
	    VALUE v_color = rb_funcall(v_colorsym, rb_intern("color"), 0);
	    RQTDECLARE_COLOR(color);
	    *self = *color;
	    return Qnil;
	  }
	break;
    case T_STRING:
      {
	trace("when String");
	char *s = StringValueCStr(v_colorsym);
	if (*s == '#')
	  {
	    const size_t l = strlen(s);
	    char t[l + 1];
	    strcpy(t, s);
	    s = t;
	    for (char *t = s; *t; t++)
	      *t = toupper(*t);
	    switch (l)
	      {
	      case 5:
		{
		  // 17 * 0xf = 17 * 15 = 255. How nice.
		  const int alpha = hex2int(s[4]) * 17;
		  s[4] = 0;
		  QColor * const r = new QColor(s);
		  r->setAlpha(alpha);
		  *self = *r;
		  return Qnil;
		}
	      case 9:
		{
		  const int alpha = hex2int(s[7]) * 16 + hex2int(s[8]);
		  s[7] = 0;
		  QColor * const r = new QColor(s);
		  r->setAlpha(alpha);
		  *self = *r;
		  return Qnil;
		}
	      case 13:
		{
		  const int alpha = hex2int(s[10]) * 256 + hex2int(s[11]) * 16 + hex2int(s[12]);
		  s[10] = 0;
		  QColor * const r = new QColor(s);
		  r->setAlphaF(alpha / 4096.0);
		  *self = *r;
		  return Qnil;
		}
	      case 17:
		{
		  const int alpha = hex2int(s[13]) * 65536 + hex2int(s[14]) * 256 
				    + hex2int(s[15]) * 16 + hex2int(s[16]);
		  s[13] = 0;
		  QColor * const r = new QColor(s);
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
	trace("when Array");
	return cColor_initialize(RARRAY_LEN(v_colorsym), RARRAY_PTR(v_colorsym), v_self);
    case T_FIXNUM:
      {
	trace("when Fixnum");
	if (NIL_P(v_b))
	  {
	    const int gray = NUM2INT(v_colorsym);
	    const int alpha = NIL_P(v_g) ? 255 : NUM2INT(v_g);
	    *self = QColor(gray, gray, gray, alpha);
	    return Qnil;
	  }
	const int alpha = NIL_P(v_a) ? 255 : NUM2INT(v_a);
	*self = QColor(NUM2INT(v_colorsym), NUM2INT(v_g), NUM2INT(v_b), alpha);
	return Qnil;
      }
    case T_FLOAT:
      {
	trace("when Float");
	if (NIL_P(v_b))
	  {
	    const double gray = NUM2DBL(v_colorsym);
	    const double alpha = NIL_P(v_g) ? 1.0 : NUM2DBL(v_g);
	    *self = QColor(gray, gray, gray, alpha);
	    return Qnil;
	  }
	const double alpha = NIL_P(v_a) ? 1.0 : NUM2DBL(v_a);
	*self = QColor(NUM2DBL(v_colorsym), NUM2DBL(v_g), NUM2DBL(v_b), alpha);
	return Qnil;
      }
    case T_SYMBOL:
      {
	trace("when Symbol");
	VALUE v_color = cColor_sym2color(cColor, v_colorsym);
	RQTDECLARE_COLOR(color);
	*self = *color;
	return Qnil;
      }
    } // switch TYPE v_colorsym
  rb_raise(rb_eArgError, "invalid color %s, %s, %s, %s", INSPECT(v_colorsym), INSPECT(v_g),
	   INSPECT(v_b), INSPECT(v_a));
} // cColor_initialize

void 
init_color(VALUE mQt)
{
  trace("init_color");
  cColor = rb_define_class_under(mQt, "Color", cNoQtControl);
  rb_define_alloc_func(cColor, cColor_alloc);
  rb_define_module_function(cColor, "sym2color", RUBY_METHOD_FUNC(cColor_sym2color), 1);
  rb_define_private_method(cColor, "initialize", RUBY_METHOD_FUNC(cColor_initialize), -1);
  trace("DONE init_color");
}

} // namespace R_Qt 
