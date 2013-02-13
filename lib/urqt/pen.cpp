
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

//#define TRACE

#pragma implementation
#include "pen.h"
#include "graphicsitem.h"
#include "brush.h"

namespace R_Qt {

VALUE
cPen = Qnil;

static void
cPen_free(QPen *pen)
{
  traqt1("delete QPen %p", pen);
  delete pen;
}

static inline VALUE
cPenWrap(QPen *pen)
{
  trace1("cPenWrap(%p)", pen);
  return Data_Wrap_Struct(cPen, 0, cPen_free, pen);
}

R_QT_DEF_ALLOCATOR_BASE1(Pen)

static void
anything_else(QPen *self, VALUE v_args)
{
  track1("Anything else: %s", v_args);
  VALUE v_color = rb_class_new_instance(1, &v_args, cColor);
  RQTDECLARE_COLOR(color);
  traqt("QPen(QColor)");
  *self = QPen(*color);
}

static void
reattach(VALUE v_self, QPen *self)
{
  track1("%s::reattach", v_self);
  const VALUE v_parent = rb_iv_get(v_self, "@parent");
  if (NIL_P(v_parent)) return;
  if (rb_obj_is_kind_of(v_parent, cGraphicsLineItem))
    {
      RQTDECLARE_GI(QGraphicsLineItem, parent);
      parent->setPen(*self);
    }
  else
    {
      RQTDECLARE_GI(QAbstractGraphicsShapeItem, parent);
      trace2("parent.class=%s, parent=%p", rb_obj_classname(v_parent), parent);
      trace3("color_set, call setPen %s (QPen:%p) on parent %s", TO_CSTR(v_self), self, 
	     TO_CSTR(v_parent));
      trace2("parent.class=%s, parent=%p", rb_obj_classname(v_parent), parent);
      traqt1("%p::setPen", parent);
      parent->setPen(*self);
    }
}

// This is in fact almost identical to cBrush_initialize
static VALUE
cPen_initialize(int argc, VALUE *argv, VALUE v_self)
{
  trace1("cPen, argc = %d", argc);
  RQTDECLARE_PEN(self);
  VALUE v_args, v_parent = Qnil;
  if (argc == 0)
      v_args = Qnil;
  if (argc == 1)
    {
      v_args = argv[0];  // this can be a T_ARRAY...
      if (rb_obj_is_kind_of(v_args, cGraphicsItem))
	{
	  trace("located parent as argv0");
	  v_parent = v_args;
	  v_args = Qnil;
	}
    }
  else // argc > 1
    {
      if (rb_obj_is_kind_of(argv[0], cGraphicsItem))
	{
	  track1("located parent '%s' as argv0, shift", argv[0]);
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
	if (rb_obj_is_kind_of(v_args, cPen))
	  {
	    track1("Pen %s", v_args);
	    RQTDECLARE_PEN(args);
	    *self = *args;
	  }
	else if (rb_obj_is_kind_of(v_args, cColor))
	  {
	    track1("Color %s", v_args);
	    RQTDECLARE_COLOR(args);
	    traqt("QPen(QColor)");
	    *self = QPen(*args);
	  }
	else
	    anything_else(self, v_args);
	break;
    case T_FALSE:
	trace("false");
	traqt("QPen(NoPen)");
	*self = QPen(Qt::NoPen);
	break;
    case T_SYMBOL:
      {
	const ID id = SYM2ID(v_args);
	if (id == rb_intern("none")
	    || id == rb_intern("nopen")
	    || id == rb_intern("no_pen"))
	  {
	    trace(":none, :nopen, :no_pen");
	    traqt("QPen(NoPen)");
	    *self = QPen(Qt::NoPen);
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
	track1("String %s", v_args);
	VALUE v_color = rb_class_new_instance(1, &v_args, cColor);
	RQTDECLARE_COLOR(color);
	trace3("v_color=%d,%d,%d", color->red(), color->green(), color->blue());
	trace1("QColorptr = %p", color);
	traqt("QPen(QColor)");
	*self = QPen(*color);
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
	traqt("QPen(QColor)");
	*self = QPen(*color);
	break;
      }
    default:
	anything_else(self, v_args);
	break;
    } // switch TYPE
  // Late assignment, because model_init_path may have changed the color.
  // Even though it should already have called setPen in that case.
  reattach(v_self, self);
  return Qnil;
} // cPen_initialize

static VALUE
cPen_parent_set(VALUE v_self, VALUE v_parent)
{
  rb_check_frozen(v_self);
  VALUE v_old_parent = rb_iv_get(v_self, "@parent");
  if (!NIL_P(v_old_parent))
    rb_funcall(v_old_parent, rb_intern("pen="), 1, Qnil);
  rb_iv_set(v_self, "@parent", v_parent);
  if (!NIL_P(v_parent))
    rb_funcall(v_parent, rb_intern("pen="), 1, v_self);
  return v_parent;
}

static VALUE
cPen_apply_model(VALUE v_self, VALUE v_data)
{
  return rb_funcall(v_self, rb_intern("apply_dynamic_setter"), 2, CSTR2SYM("color"), v_data);
}

static VALUE
cPen_color_set(VALUE v_self, VALUE v_data)
{
  track2("%s::color_set(%s)", v_self, v_data);
  rb_check_frozen(v_self);
  RQTDECLARE_PEN(self);
  VALUE v_color = rb_class_new_instance(1, &v_data, cColor);
  RQTDECLARE_COLOR(color);
  traqt1("%p::setColor", self);
  trace4("color_set: v_self=%s, color=(%d,%d,%d)", INSPECT(v_self), color->red(), 
	 color->green(), color->blue());
  // INCORRECT self->setColor(*color);
  *self = QPen(*color);
  trace5("self=%p, pen.color=(%d,%d,%d,%d)", self,
         self->color().red(), self->color().green(), self->color().blue(), 
	 self->color().alpha());
  reattach(v_self, self);
  //parent->update();	CHANGE STILL INVISIBLE 
  return v_data;
}

static VALUE
cPen_color_get(VALUE v_self)
{
  track1("%s::color_get()", v_self);
  RQTDECLARE_PEN(self);
  return cColorWrap(self->color());
} // cPen_color_get

static VALUE
cPen_widthF_set(VALUE v_self, VALUE v_widthF)
{
  track2("%s::widthF_set(%s)", v_self, v_widthF);
  rb_check_frozen(v_self);
  RQTDECLARE_PEN(self);
  if (TYPE(v_widthF) == T_SYMBOL && v_widthF == CSTR2SYM("cosmetic"))
    self->setWidthF(0);
  else
    self->setWidthF(NUM2DBL(v_widthF));
  reattach(v_self, self);
  return v_widthF;
}

static VALUE
cPen_widthF_get(VALUE v_self)
{
  RQTDECLARE_PEN(self);
  return DBL2NUM(self->widthF());
}

static VALUE
cPen_capStyle_set(VALUE v_self, VALUE v_style)
{
  track2("%s::capStyle= %s", v_self, v_style);
  rb_check_frozen(v_self);
  RQTDECLARE_PEN(self);
  VALUE v_capstyles = rb_cv_get(cPen, "@@capstyles");
  if (TYPE(v_capstyles) != T_HASH)
    {
      v_capstyles = rb_hash_new();
      rb_cv_set(cPen, "@@capstyles", v_capstyles);
#define QTCAPSTYLE_DO(sym, qtstyle) \
      rb_hash_aset(v_capstyles, CSTR2SYM(#sym), INT2NUM(Qt::qtstyle##Cap))
      QTCAPSTYLE_DO(default, Square);
      QTCAPSTYLE_DO(square, Square);
      QTCAPSTYLE_DO(squarecap, Square);
      QTCAPSTYLE_DO(project, Square);
      QTCAPSTYLE_DO(flat, Flat);
      QTCAPSTYLE_DO(flatcap, Flat);
      QTCAPSTYLE_DO(round, Round);
      QTCAPSTYLE_DO(roundcap, Round);
    }
  self->setCapStyle(Qt::PenCapStyle(NUM2INT(rb_hash_aref(v_capstyles, v_style))));
  return v_style;
}

static VALUE
cPen_capStyle_get(VALUE v_self)
{
  RQTDECLARE_PEN(self);
  switch (self->capStyle())
    {
      case Qt::SquareCap: return CSTR2SYM("square");
      case Qt::FlatCap: return CSTR2SYM("flat");
      case Qt::RoundCap: return CSTR2SYM("round");
      default: break;
    }
  rb_raise(rb_eRuntimeError, "Unhandled capstyle %d", self->capStyle());
}

static VALUE
cPen_joinStyle_set(VALUE v_self, VALUE v_style)
{
  track2("%s::joinStyle= %s", v_self, v_style);
  rb_check_frozen(v_self);
  RQTDECLARE_PEN(self);
  VALUE v_joinstyles = rb_cv_get(cPen, "@@joinstyles");
  if (TYPE(v_joinstyles) != T_HASH)
    {
      v_joinstyles = rb_hash_new();
      rb_cv_set(cPen, "@@joinstyles", v_joinstyles);
#define QTJOINSTYLE_DO(sym, qtstyle) \
      rb_hash_aset(v_joinstyles, CSTR2SYM(#sym), INT2NUM(Qt::qtstyle##Join))
      QTJOINSTYLE_DO(default, Bevel);
      QTJOINSTYLE_DO(miter, Miter);
      QTJOINSTYLE_DO(miterjoin, Miter);
      QTJOINSTYLE_DO(bevel, Bevel);
      QTJOINSTYLE_DO(beveljoin, Bevel);
      QTJOINSTYLE_DO(round, Round);
      QTJOINSTYLE_DO(roundjoin, Round);
    }
  self->setJoinStyle(Qt::PenJoinStyle(NUM2INT(rb_hash_aref(v_joinstyles, v_style))));
  return v_style;
}

static VALUE
cPen_joinStyle_get(VALUE v_self)
{
  RQTDECLARE_PEN(self);
  switch (self->joinStyle())
    {
      case Qt::MiterJoin: return CSTR2SYM("miter");
      case Qt::BevelJoin: return CSTR2SYM("bevel");
      case Qt::RoundJoin: return CSTR2SYM("round");
      default: break;
    }
  rb_raise(rb_eRuntimeError, "Unhandled joinstyle %d", self->joinStyle());
}

void 
init_pen(VALUE mQt)
{
  trace("init_pen");
  cPen = rb_define_class_under(mQt, "Pen", cNoQtControl);
  rb_define_alloc_func(cPen, cPen_alloc);
  rb_define_const(cPen, "NoPen", Qt::NoPen);
  rb_define_private_method(cPen, "initialize", 
			   RUBY_METHOD_FUNC(cPen_initialize), -1);
  rb_define_method(cPen, "parent=", RUBY_METHOD_FUNC(cPen_parent_set), 1);
  rb_define_method(cPen, "apply_model", RUBY_METHOD_FUNC(cPen_apply_model), 1);
  rb_define_method(cPen, "color=", RUBY_METHOD_FUNC(cPen_color_set), 1);
  rb_define_method(cPen, "color_get", RUBY_METHOD_FUNC(cPen_color_get), 0);
  VALUE v_hash = rb_hash_new();
  rb_hash_aset(v_hash, CSTR2SYM("klass"), cDynamicColor);
  rb_hash_aset(v_hash, CSTR2SYM("require"), rb_str_new_cstr("dynamic_color"));
  trace("create color attribute with dynattrclass = DynamicColor");
  rb_funcall(cPen, rb_intern("attr_dynamic"), 3, cColor, CSTR2SYM("color"), v_hash);
  rb_define_method(cPen, "widthF=", RUBY_METHOD_FUNC(cPen_widthF_set), 1);
  rb_define_method(cPen, "widthF_get", RUBY_METHOD_FUNC(cPen_widthF_get), 0);
  rb_funcall(cPen, rb_intern("attr_dynamic"), 2, rb_cFloat, CSTR2SYM("widthF"));
  rb_define_alias(cPen, "width", "widthF");
  rb_define_alias(cPen, "size", "widthF");
  rb_define_alias(cPen, "weight", "widthF");
  rb_define_method(cPen, "capStyle=", RUBY_METHOD_FUNC(cPen_capStyle_set), 1);
  rb_define_method(cPen, "capStyle_get", RUBY_METHOD_FUNC(cPen_capStyle_get), 0);
  rb_funcall(cPen, rb_intern("attr_dynamic"), 2, rb_cSymbol, CSTR2SYM("capStyle"));
  rb_define_alias(cPen, "cap", "capStyle");
  rb_define_class_variable(cPen, "@@capstyles", Qnil);
  rb_define_method(cPen, "joinStyle=", RUBY_METHOD_FUNC(cPen_joinStyle_set), 1);
  rb_define_method(cPen, "joinStyle_get", RUBY_METHOD_FUNC(cPen_joinStyle_get), 0);
  rb_funcall(cPen, rb_intern("attr_dynamic"), 2, rb_cSymbol, CSTR2SYM("joinStyle"));
  rb_define_alias(cPen, "join", "joinStyle");
  rb_define_class_variable(cPen, "@@joinstyles", Qnil);
}

} // namespace R_Qt 
