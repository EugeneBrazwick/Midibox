
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

//#define TRACE

#pragma implementation
#include "pen.h"
#include "graphicsitem.h"
#include "color.h"
#include "ruby++/array.h"
#include "ruby++/hash.h"

namespace R_Qt {

RPP::Class
cPen;

// Used by R_QT_DEF_ALLOCATOR_BASE1
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
reattach(RPP::QPen self)
{
  track1("%s::reattach", self);
  const RPP::Object parent = self.iv("@parent");
  if (parent.isNil()) return;
  parent.call("pen=", self);
}

// This is in fact almost identical to cBrush_initialize
static VALUE
cPen_initialize(int argc, VALUE *argv, VALUE v_self)
{
  trace1("cPen, argc = %d", argc);
  RPP::QPen self = v_self;
  RPP::Object args, parent;
  if (argc == 1)
    {
      args = argv[0];  // this can be a T_ARRAY...
      if (args.is_kind_of(cGraphicsItem))
	{
	  trace("located parent as argv0");
	  parent = args;
	  args = Qnil;
	}
    }
  else if (argc > 1)
    {
      args = argv[0];
      if (args.is_kind_of(cGraphicsItem))
	{
	  track1("located parent '%s' as argv0, shift", args);
	  parent = args;
	  argc--, argv++;
	} 
      if (argc == 1)
	args = argv[0];
      else
	args = RPP::Array(argc, argv);
    }
  if (parent.test())
    self.call("parent=", parent);
  switch (args.type())
    {
    case T_DATA:
	if (args.is_kind_of(cPen))
	  {
	    track1("Pen %s", args);
	    *self = *RPP::QPen(args);
	  }
	else if (args.is_kind_of(cColor))
	  {
	    track1("Color %s", v_args);
	    *self = QPen(RPP::QColor(args));
	    traqt("QPen(QColor)");
	  }
	else
	    anything_else(self, args);
	break;
    case T_FALSE:
	trace("false");
	traqt("QPen(NoPen)");
	*self = QPen(Qt::NoPen);
	break;
    case T_SYMBOL:
      {
	const RPP::Symbol sym(args);
	if (sym == "none" || sym == "nopen" || sym == "no_pen")
	  {
	    trace(":none, :nopen, :no_pen");
	    *self = QPen(Qt::NoPen);
	  }
	else
	    anything_else(self, args);
	break;
      }
    case T_NIL:
	if (self.block_given())
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
	track1("String %s", args);
	const RPP::QColor color(cColor.new_instance(args));
/* FOR:	VALUE v_color = rb_class_new_instance(1, &v_args, cColor);
	RQTDECLARE_COLOR(color);
	*/
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
	*self = QPen(*RPP::QColor(cColor.new_instance(RPP::Array(args, RPP::VERYUNSAFE))));
	/* FOR :
	VALUE v_color = rb_class_new_instance(RARRAY_LEN(v_args), RARRAY_PTR(v_args), cColor);
	RQTDECLARE_COLOR(color);
	traqt("QPen(QColor)");
	*self = QPen(*color);
	*/
	break;
      }
    default:
	anything_else(self, args);
	break;
    } // switch TYPE
  // Late assignment, because model_init_path may have changed the color.
  // Even though it should already have called setPen in that case.
  reattach(self);
  return Qnil;
} // cPen_initialize

static VALUE
cPen_parent_set(VALUE v_self, VALUE v_parent)
{
  const RPP::Object self = v_self;
  const RPP::Object parent = v_parent;
  const RPP::Object old_parent = self.iv("@parent");
  if (old_parent.test())
    old_parent.call("pen=", Qnil);
  self.iv_set("@parent", parent);
  if (parent.test())
    parent.call("pen=", self);
  return v_parent;
}

static VALUE
cPen_apply_model(VALUE v_self, VALUE v_data)
{
  const RPP::Object self = v_self;
  return self.call("apply_dynamic_setter", RPP::Symbol("color"), v_data);
}

static VALUE
cPen_color_set(VALUE v_self, VALUE v_data)
{
  track2("%s::color_set(%s)", v_self, v_data);
  RPP::QPen self = v_self;
  self.check_frozen();
  const RPP::QColor color = cColor.new_instance(v_data);
  traqt1("%p::setColor", self);
  trace4("color_set: v_self=%s, color=(%d,%d,%d)", self.inspect(), color->red(), 
	 color->green(), color->blue());
  // INCORRECT self->setColor(*color);
  *self = QPen(*color);
  trace5("self=%p, pen.color=(%d,%d,%d,%d)", self,
         self->color().red(), self->color().green(), self->color().blue(), 
	 self->color().alpha());
  reattach(self);
  //parent->update();	CHANGE STILL INVISIBLE 
  return v_data;
}

static VALUE
cPen_color_get(VALUE v_self)
{
  track1("%s::color_get()", v_self);
  return RPP::QColor(RPP::QPen(v_self)->color());
} // cPen_color_get

static VALUE
cPen_widthF_set(VALUE v_self, VALUE v_widthF)
{
  track2("%s::widthF_set(%s)", v_self, v_widthF);
  const RPP::QPen self = v_self;
  self.check_frozen();
  if (SYMBOL_P(v_widthF))
    {
      const RPP::Symbol w = v_widthF;
      if (w == "cosmetic")
	self->setWidthF(0);
      else
	rb_raise(rb_eArgError, "unknown penwidth :%s", w.to_s());
    }
  else
      self->setWidthF(RPP::Float(v_widthF));
  reattach(self);
  return v_widthF;
}

static VALUE
cPen_widthF_get(VALUE v_self)
{
  const RPP::QPen self = v_self;
  return RPP::Float(self->widthF());
}

static VALUE
cPen_capStyle_set(VALUE v_self, VALUE v_style)
{
  track2("%s::capStyle= %s", v_self, v_style);
  const RPP::QPen self = v_self;
  self.check_frozen();
  RPP::Dictionary capstyles(cPen.cv("@@capstyles"), RPP::VERYUNSAFE);
  if (!capstyles.isHash())
    {
      capstyles = RPP::Dictionary();
      cPen.cv_set("@@capstyles", capstyles);
#define QTCAPSTYLE_DO(sym, qtstyle) \
      capstyles[#sym] = RPP::Fixnum(Qt::qtstyle##Cap)
      QTCAPSTYLE_DO(default, Square);
      QTCAPSTYLE_DO(square, Square);
      QTCAPSTYLE_DO(squarecap, Square);
      QTCAPSTYLE_DO(project, Square);
      QTCAPSTYLE_DO(flat, Flat);
      QTCAPSTYLE_DO(flatcap, Flat);
      QTCAPSTYLE_DO(round, Round);
      QTCAPSTYLE_DO(roundcap, Round);
    }
  self->setCapStyle(Qt::PenCapStyle(RPP::Fixnum(capstyles[v_style]).to_i()));
  return v_style;
}

static VALUE
cPen_capStyle_get(VALUE v_self)
{
  const RPP::QPen self = v_self;
  switch (self->capStyle())
    {
      case Qt::SquareCap: return RPP::Symbol("square");
      case Qt::FlatCap: return RPP::Symbol("flat");
      case Qt::RoundCap: return RPP::Symbol("round");
      default: break;
    }
  rb_raise(rb_eRuntimeError, "Unhandled capstyle %d", self->capStyle());
}

static VALUE
cPen_joinStyle_set(VALUE v_self, VALUE v_style)
{
  track2("%s::joinStyle= %s", v_self, v_style);
  const RPP::QPen self = v_self;
  self.check_frozen();
  RPP::Dictionary joinstyles(cPen.cv("@@joinstyles"), RPP::VERYUNSAFE);
  if (!joinstyles.isHash())
    {
      joinstyles = RPP::Dictionary();
      cPen.cv_set("@@joinstyles", joinstyles);
#define QTJOINSTYLE_DO(sym, qtstyle) \
      joinstyles[#sym] = RPP::Fixnum(Qt::qtstyle##Join)
      QTJOINSTYLE_DO(default, Bevel);
      QTJOINSTYLE_DO(miter, Miter);
      QTJOINSTYLE_DO(miterjoin, Miter);
      QTJOINSTYLE_DO(bevel, Bevel);
      QTJOINSTYLE_DO(beveljoin, Bevel);
      QTJOINSTYLE_DO(round, Round);
      QTJOINSTYLE_DO(roundjoin, Round);
    }
  self->setJoinStyle(Qt::PenJoinStyle(RPP::Fixnum(joinstyles[v_style]).to_i()));
  return v_style;
}

static VALUE
cPen_joinStyle_get(VALUE v_self)
{
  const RPP::QPen self = v_self;
  switch (self->joinStyle())
    {
      case Qt::MiterJoin: return RPP::Symbol("miter");
      case Qt::BevelJoin: return RPP::Symbol("bevel");
      case Qt::RoundJoin: return RPP::Symbol("round");
      default: break;
    }
  rb_raise(rb_eRuntimeError, "Unhandled joinstyle %d", self->joinStyle());
}

void 
init_pen(RPP::Module qt)
{
  trace("init_pen");
  cPen = qt.define_class("Pen", cNoQtControl);
  cPen.define_alloc_func(cPen_alloc)
      .define_private_method("initialize", cPen_initialize)
      .define_method("parent=", cPen_parent_set)
      .define_method("apply_model", cPen_apply_model)
      .define_method("color=", cPen_color_set)
      .define_method("color_get", cPen_color_get)
      .define_method("widthF=", cPen_widthF_set)
      .define_method("widthF_get", cPen_widthF_get)
      .define_method("capStyle=", cPen_capStyle_set)
      .define_method("capStyle_get", cPen_capStyle_get)
      .define_method("joinStyle=", cPen_joinStyle_set)
      .define_method("joinStyle_get", cPen_joinStyle_get)
      ;
}

} // namespace R_Qt 
