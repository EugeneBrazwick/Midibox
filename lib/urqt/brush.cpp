
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

//#define TRACE

#pragma implementation
#include "brush.h"
#include "graphicsitem.h"
#include <assert.h>
#include <QtGui/QBrush>
#include <QtWidgets/QGraphicsScene>

namespace R_Qt {

VALUE 
cBrush = Qnil, cColor = Qnil;

void
cBrush_free(QBrush *brush)
{
  traqt1("delete QBrush %p", brush);
  delete brush;
}

static void
reattach_brush(VALUE v_self, QBrush *self)
{
  trace("reattach_brush");
  const VALUE v_parent = rb_iv_get(v_self, "@parent");
  track1("parent = %s", v_parent);
  if (rb_obj_is_kind_of(v_parent, cGraphicsScene))
    {
      trace("setBackgroundBrush");
      RQTDECLARE(QGraphicsScene, parent);
      parent->setBackgroundBrush(*self);
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
  VALUE v_color = rb_class_new_instance(1, &v_args, cColor);
  RQTDECLARE_COLOR(color);
  traqt("QBrush()");
  *self = QBrush(*color);
} // anything_else

static VALUE
cBrush_initialize(int argc, VALUE *argv, VALUE v_self)
{
  trace1("cBrush_initialize, argc = %d", argc);
  RQTDECLARE_BRUSH(self);
  VALUE v_args, v_parent = Qnil;
  if (argc == 0)
      v_args = Qnil;
  if (argc == 1)
    {
      v_args = argv[0];  // this can be a T_ARRAY...
      if (rb_obj_is_kind_of(v_args, cGraphicsItem)
	  || rb_obj_is_kind_of(v_args, cGraphicsScene))
	{
	  trace("located parent as argv0");
	  v_parent = v_args;
	  v_args = Qnil;
	}
    }
  else // argc > 1
    {
      if (rb_obj_is_kind_of(argv[0], cGraphicsItem)
	  || rb_obj_is_kind_of(argv[0], cGraphicsScene))
	{
	  trace("located parent as argv0, shift");
	  v_parent = argv[0];
	  argc--, argv++;
	} 
      if (argc == 1)
	v_args = argv[0];
      else
	v_args = rb_ary_new4(argc, argv);
    }
  if (!NIL_P(v_parent))
    rb_funcall(v_self, rb_intern("parent="), 1, v_parent);
  switch (TYPE(v_args))
    {
    case T_DATA:
	if (rb_obj_is_kind_of(v_args, cBrush))
	  {
	    track1("Brush %s", v_args);
	    RQTDECLARE_BRUSH(args);
	    *self = *args;
	  }
	else if (rb_obj_is_kind_of(v_args, cColor))
	  {
	    track1("Color %s", v_args);
	    RQTDECLARE_COLOR(args);
	    traqt("QBrush()");
	    *self = QBrush(*args);
	  }
	else
	    anything_else(self, v_args);
	break;
    case T_FALSE:
	trace("false");
	traqt("QBrush(NoBrush)");
	*self = QBrush(Qt::NoBrush);
	break;
    case T_SYMBOL:
      {
	const ID id = SYM2ID(v_args);
	if (id == rb_intern("none")
	    || id == rb_intern("nobrush")
	    || id == rb_intern("no_brush"))
	  {
	    trace(":none, :nobrush, :no_brush");
	    traqt("QBrush(NoBrush)");
	    *self = QBrush(Qt::NoBrush);
	  }
	else
	    anything_else(self, v_args);
	break;
      }
    case T_NIL:
	if (rb_block_given_p())
	  {
	    trace("&block");
	    rb_obj_instance_eval(0, 0, v_self);
	  }
	else
	    anything_else(self, v_args);
	break;
    case T_HASH:
	track1("Hash %s", v_args);
	rb_funcall(v_self, rb_intern("setupQuickyhash"), 1, v_args); 
	break;
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
	traqt("QBrush(QColor)");
	*self = QBrush(*color);
	trace3("self.color=%d,%d,%d", self->color().red(), self->color().green(),
	       self->color().blue());
	trace1("self.style=%d", self->style());
	break;
      }
    case T_ARRAY:
      {
	track1("Array %s", v_args);
	VALUE v_color = rb_class_new_instance(RARRAY_LEN(v_args), RARRAY_PTR(v_args), cColor);
	RQTDECLARE_COLOR(color);
	traqt("QBrush(QColor)");
	*self = QBrush(*color);
	break;
      }
    default:
	anything_else(self, v_args);
	break;
    } // switch TYPE
  // Late assignment, because model_init_path may have changed the color.
  // Even though it should already have called setBrush in that case.
  if (!NIL_P(v_parent))
    reattach_brush(v_self, self);
  trace("cBrush_initialize OK");
  return Qnil;
} // cBrush_initialize

R_QT_DEF_ALLOCATOR_BASE1(Brush)

static VALUE
cBrush_parent_set(VALUE v_self, VALUE v_parent)
{
  rb_check_frozen(v_self);
  VALUE v_old_parent = rb_iv_get(v_self, "@parent");
  if (!NIL_P(v_old_parent))
    rb_funcall(v_old_parent, rb_intern("brush="), 1, Qnil);
  rb_iv_set(v_self, "@parent", v_parent);
  if (!NIL_P(v_parent))
    rb_funcall(v_parent, rb_intern("brush="), 1, v_self);
  return v_parent;
} // cBrush_parent_set

static VALUE
cBrush_apply_model(VALUE v_self, VALUE v_data)
{
  return rb_funcall(v_self, rb_intern("apply_dynamic_setter"), 2, CSTR2SYM("color"), v_data);
} // cBrush_apply_model

static VALUE
cBrush_color_set(VALUE v_self, VALUE v_data)
{
  track2("%s::color_set(%s)", v_self, v_data);
  rb_check_frozen(v_self);
  RQTDECLARE_BRUSH(self);
  VALUE v_color = rb_class_new_instance(1, &v_data, cColor);
  RQTDECLARE_COLOR(color);
  traqt1("%p::setColor", self);
  trace4("color_set: v_self=%s, color=(%d,%d,%d)", INSPECT(v_self), color->red(), color->green(), color->blue());
  // INCORRECT self->setColor(*color);
  *self = QBrush(*color);
  trace5("self=%p, brush.color=(%d,%d,%d,%d)", self,
         self->color().red(), self->color().green(), self->color().blue(), self->color().alpha());
  reattach_brush(v_self, self);
  return v_data;
} // cBrush_color_set

static VALUE
cBrush_color_get(VALUE v_self)
{
  track1("%s::color_get()", v_self);
  RQTDECLARE_BRUSH(self);
  return cColorWrap(self->color());
} // cBrush_color_get

void 
init_brush(VALUE mQt)
{
  trace("init_brush");
  cBrush = rb_define_class_under(mQt, "Brush", cNoQtControl);
  rb_define_alloc_func(cBrush, cBrush_alloc);
  rb_define_const(cBrush, "NoBrush", Qt::NoBrush);
  rb_define_private_method(cBrush, "initialize", RUBY_METHOD_FUNC(cBrush_initialize), -1);
  rb_define_method(cBrush, "parent=", RUBY_METHOD_FUNC(cBrush_parent_set), 1);
  rb_define_method(cBrush, "apply_model", RUBY_METHOD_FUNC(cBrush_apply_model), 1);
  rb_define_method(cBrush, "color=", RUBY_METHOD_FUNC(cBrush_color_set), 1);
  rb_define_method(cBrush, "color_get", RUBY_METHOD_FUNC(cBrush_color_get), 0);
  rb_funcall(cBrush, rb_intern("attr_dynamic"), 2, cColor, CSTR2SYM("color"));
} // init_brush

R_QT_DEF_ALLOCATOR_BASE1(Color)

static Qt::GlobalColor
cColor_sym2color(VALUE v_self, VALUE v_sym)
{
  track2("%s::sym2color(%s)", v_self, v_sym);
  VALUE v_colors = rb_iv_get(v_self, "@color");
  if (NIL_P(v_colors))
    {
      trace("setup @color hash");
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
  track1("Check_Type(%s, T_HASH)", v_colors);
  Check_Type(v_colors, T_HASH);
  return Qt::GlobalColor(NUM2INT(rb_hash_aref(v_colors, v_sym)));
} // cColor_sym2color

// where hex is in range '0'..'9' or 'A'..'F'
static inline int
hex2int(int hex)
{
  return hex - (hex >= 'A' ? 'A' - 10 : '0');
} // hex2int

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
	const Qt::GlobalColor gc = cColor_sym2color(cColor, v_colorsym);
	*self = QColor(gc);
	return Qnil;
      }
    } // switch TYPE v_colorsym
  rb_raise(rb_eArgError, "invalid color %s, %s, %s, %s", INSPECT(v_colorsym), INSPECT(v_g),
	   INSPECT(v_b), INSPECT(v_a));
} // cColor_initialize

void 
cColor_free(QColor *color)
{
  traqt1("delete QColor %p", color);
  delete color;
} // cColor_free

void 
init_color(VALUE mQt)
{
  trace("init_color");
  cColor = rb_define_class_under(mQt, "Color", cNoQtControl);
  rb_define_alloc_func(cColor, cColor_alloc);
  //  rb_define_module_function(cColor, "sym2color", RUBY_METHOD_FUNC(cColor_sym2color), 1);
  rb_define_private_method(cColor, "initialize", RUBY_METHOD_FUNC(cColor_initialize), -1);
  trace("DONE init_color");
}

} // namespace R_Qt 
