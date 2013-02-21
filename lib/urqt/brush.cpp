
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

//#define TRACE

#pragma implementation
#include "brush.h"
#include "graphicsitem.h"
#include "object.h"
#include "color.h"
#include "ruby++/dataobject.h"
#include "ruby++/array.h"
#include "ruby++/hash.h"
#include <assert.h>
#include <QtWidgets/QGraphicsScene>

namespace R_Qt {

RPP::Class 
cBrush;

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
	const ID id = RPP::Symbol(args, RPP::VERYUNSAFE).to_id();	// FIXME. Need Id class I guess
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
	*self = QBrush(*RPP::QColor(cColor.new_instance(RPP::Array(args, RPP::VERYUNSAFE))));
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
	.define_method("color=", cBrush_color_set)
	.define_method("color_get", cBrush_color_get)
	;
  RPP::Dictionary hash;
  hash["klass"] = cDynamicColor;
  hash["require"] = "dynamic_color";
  cBrush.call("attr_dynamic", cColor, RPP::Symbol("color"), hash);
} // init_brush

} // namespace R_Qt 
