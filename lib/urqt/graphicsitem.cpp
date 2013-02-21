
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

//#define TRACE

#pragma implementation
#include "graphicsitem.h"
#include "brush.h"
#include "size.h"
#include "object.h"
#include "pen.h"
#include "painterpath.h"
#include "point.h"
#include "color.h"
#include "ruby++/rppstring.h"
#include "ruby++/array.h"
#include <assert.h>
#include <QtGui/QBrush>

namespace R_Qt {

RPP::Class 
cRectF;

RPP::Class
cGraphicsItem,
cAbstractGraphicsShapeItem,
cSynthItem,
cGraphicsLineItem;

void
cRectF_free(QRectF *rect)
{
  trace1("cRectF_free(%p)", rect);
  traqt1("delete QRectF %p", rect);
  delete rect;
}

R_QT_DEF_ALLOCATOR_BASE1(RectF)

QRectF
args2QRectF(int argc, VALUE *argv)
{
  trace1("args2QRectF, argc=%d", argc);
  VALUE v_x, v_y, v_w, v_h;
  rb_scan_args(argc, argv, "13", &v_x, &v_y, &v_w, &v_h);
  if (NIL_P(v_y) && TYPE(v_x) == T_ARRAY)
    {
      switch (RARRAY_LEN(v_x))
	{
	case 4:
	  v_h = RARRAY_PTR(v_x)[3];
	  v_w = RARRAY_PTR(v_x)[2];
	  // fall through
	case 2:
	  v_y = RARRAY_PTR(v_x)[1];
	  // fall through
	case 1:
	  v_x = RARRAY_PTR(v_x)[0];
	  break;
	default:
	  rb_raise(rb_eTypeError, "invalid arraylength for a rectangle");
	}
    }
  if (NIL_P(v_y))
    {
      switch (TYPE(v_x))
	{
	case T_DATA:
	    // v_x should be a RectF 
	    track1("v_x = %s", v_x);
	    return v2rect(v_x);
	case T_FIXNUM:
	case T_FLOAT:
	  {
	    const double sz = NUM2DBL(v_x);
	    return QRectF(0.0, 0.0, sz, sz);
	  }
	default:
	  rb_raise(rb_eTypeError, "invalid value %s to construct a rectangle", INSPECT(v_x));
	}
    }
  if (NIL_P(v_w))
    {
      switch (TYPE(v_x))
	{
	case T_FIXNUM:
	case T_FLOAT:
	  return QRectF(0.0, 0.0, NUM2DBL(v_x), NUM2DBL(v_y));
	}
      const VALUE v_pos = to_ary(v_x);
      const VALUE v_sz = to_ary(v_y);
      return QRectF(NUM2DBL(rb_ary_entry(v_pos, 0)), NUM2DBL(rb_ary_entry(v_pos, 1)),
		    NUM2DBL(rb_ary_entry(v_sz, 0)), NUM2DBL(rb_ary_entry(v_sz, 1)));
    }
  return QRectF(NUM2DBL(v_x), NUM2DBL(v_y), NUM2DBL(v_w), NUM2DBL(v_h));
}

static void 
init_rect()
{
  cRectF = mQt.define_class("RectF", rb_cObject);
  cRectF.define_alloc_func(cRectF_alloc);
}

void 
cGraphicsItem_mark(QGraphicsItem *item)
{
  if (!item) return;
  foreach (QGraphicsItem *child, item->childItems())
    {
      const VALUE v_child = item2v(child);
      if (!NIL_P(v_child))
	rb_gc_mark(v_child);
    }
  for (int i = 0; i < R_QT_GI_KEY_COUNT; i++)
    {
      traqt1("QGraphicsItem::data(%d)", i);
      const QVariant &var = item->data(i);
      trace2("i=%d (0:VALUE, 1:objectName), var=%s", i, qString2cstr(var.toString()));
      if (var.canConvert<RValue>()) // might be corrupted??
	rb_gc_mark(var.value<RValue>());
    }
} // cGraphicsItem_mark

#if defined(DEBUG)
VALUE item2v(QGraphicsItem *i)
{
  if (!i) return Qnil;
  trace1("item2v(%p)", i);
  const QVariant &rvalue = i->data(R_QT_INTERNAL_GI_KEY);
  if (!rvalue.isValid()) return Qnil;
  const RValue &rv = rvalue.value<RValue>();
  trace2("item2v(%p) -> rv %p", i, &rv);
  trace2("item2v(%p) -> VALUE = %p", i, (void *)rv.v());
  /* THIS IS CALLED BY _mark routines and hence, we may only peek.
   * INSPECT will try to modify memory though....
  trace2("item2v(%p) -> INSPECT -> %s", i, INSPECT(rv)); 
  */
  return rv; 
}
#endif // DEBUG

static void
zombify(QGraphicsItem *item)
{
  const VALUE v_item = item2v(item);
  if (!NIL_P(v_item))
    {
      trace("zombify child");
      ZOMBIFY(v_item);
    }
  traqt("QGraphicsItem::childItems");
  const QList<QGraphicsItem*> &children = item->childItems();
  foreach (QGraphicsItem *child, children) 
    zombify(child);
}

// NOTICE: do NOT call super here!!
static VALUE
cGraphicsItem_mark_ownership(VALUE v_self)
{
#if defined(DEBUG)
  QGraphicsItem * const self = 
#endif
			       v2item(v_self);
#if defined(DEBUG)
  const VALUE vdbg = item2v(self);
  assert(vdbg == v_self);
#endif
  return Qnil;
}

static VALUE 
cGraphicsItem_delete(VALUE v_self)
{
  trace1("cGraphicsItem_delete, zombified=%d", IS_ZOMBIFIED(v_self));
  if (IS_ZOMBIFIED(v_self)) return Qnil;
  const RPP::QGraphicsItem<QGraphicsItem> self = v_self;
  trace1("DELETE QGraphicsItem %p", self);
  zombify(self);
  traqt1("delete QGraphicsItem(%p)", self);
  delete &self;
  return Qnil;
}

static VALUE 
cGraphicsItem_parent_set(VALUE v_self, VALUE v_parent)
{
  track2("%s::parent_set(%s)", v_self, v_parent);
  const RPP::QGraphicsItem<QGraphicsItem> self = v_self;
  self.check_frozen();
  QGraphicsItem *parent = 0;
  if (!NIL_P(v_parent))
    GET_STRUCT_NODECL(QGraphicsItem, parent);
  trace("retrieve self");
  self->setParentItem(parent);
  return v_parent;
}

static VALUE
cGraphicsItem_objectName_set(VALUE v_self, VALUE v_newname)
{
  const RPP::QGraphicsItem<QGraphicsItem> self = v_self;
  self.check_frozen();
  self->setData(R_QT_NAME_GI_KEY, QVariant::fromValue(RValue(v_newname)));
  return v_newname;
}

static VALUE
cGraphicsItem_objectName_get(VALUE v_self)
{
  const RPP::QGraphicsItem<QGraphicsItem> self = v_self;
  const QVariant &var = self->data(R_QT_NAME_GI_KEY);
  return *var.value<RValue>();
}

static VALUE
cGraphicsItem_parent_get(VALUE v_self)
{
  trace("cGraphicsItem_parent_get");
  const RPP::QGraphicsItem<QGraphicsItem> self = v_self;
  const RPP::Object parent = self.iv("@parent");
  if (parent.test()) return parent;
  traqt("QGraphicsItem::parentItem");
  return RPP::QGraphicsItem<QGraphicsItem>(self->parentItem(), RPP::UNSAFE); // can be nil
}

static VALUE 
cGraphicsItem_enqueue_children(int argc, VALUE *argv, VALUE v_self)
{
  VALUE v_queue;
  rb_scan_args(argc, argv, "01", &v_queue);
  trace("cGraphicsItem_enqueue_children");
  track2("%s::enqueue_children(%s)", v_self, v_queue);
  const RPP::QGraphicsItem<QGraphicsItem> self = v_self;
  trace1("self = %p", self);
  trace2("self = %p, parentItem = %p, calling childItems()", self, self->parentItem());
  const QList<QGraphicsItem*> &children = self->childItems();
  trace1("#children = %d", children.count());
  const bool yield = NIL_P(v_queue);
  foreach (QGraphicsItem *child, children)
    {
      const RPP::Object v_child = item2v(child);
      if (yield)
	{
	  if (v_child.test()) v_child.yield();
	}
      else
	{
	  const RPP::Array queue = v_queue;
	  if (v_child.isNil())
	    queue.push(Data_Wrap_Struct(cSynthItem, 0, 0, child));
	  else
	    queue.push(v_child);
	}
    }
  return Qnil;
}

static VALUE
cGraphicsItem_pos_set(int argc, VALUE *argv, VALUE v_self)
{
  const RPP::QGraphicsItem<QGraphicsItem> self = v_self;
  self->setPos(ARGS2QPOINTF());
  return Qnil;
}

static VALUE
cGraphicsItem_pos_get(VALUE v_self)
{
  const RPP::QGraphicsItem<QGraphicsItem> self = v_self;
  return cPointFWrap(self->pos());
}

static VALUE
cAbstractGraphicsShapeItem_brush_set(VALUE v_self, VALUE v_brush)
{
  const RPP::QGraphicsItem<QAbstractGraphicsShapeItem> self = v_self;
  const RPP::QBrush brush(v_brush, RPP::UNSAFE);
  self.iv_set("@brush", brush);
  if (brush.isNil())
      self->setBrush(QBrush()); // default, I hope
  else
    {
      track2("%s.brush_set(%s)", v_self, v_brush);
      self->setBrush(*brush);
    }
  return v_brush;
}

// Context: Pen.parent=
static VALUE
cAbstractGraphicsShapeItem_pen_set(VALUE v_self, VALUE v_pen)
{
  const RPP::QGraphicsItem<QAbstractGraphicsShapeItem> self = v_self;
  const RPP::QPen pen(v_pen, RPP::UNSAFE);
  self.iv_set("@pen", pen);
  if (pen.isNil())
      self->setPen(QPen());
  else
    {
      track2("%s.pen_set(%s)", v_self, v_pen);
      self->setPen(*pen);
    }
  return pen;
}

static void
init_abstractgraphicsshapeitem(RPP::Module qt)
{
  cAbstractGraphicsShapeItem = qt.define_class("AbstractGraphicsShapeItem", cGraphicsItem);
  cAbstractGraphicsShapeItem.define_method("brush=", cAbstractGraphicsShapeItem_brush_set)
			    .define_method("pen=", cAbstractGraphicsShapeItem_pen_set)
			    ;
}

static inline void
init_synthitem(RPP::Module qt)
{
  cSynthItem = qt.define_class("SynthGraphicsItem", cGraphicsItem);
}

VALUE
init_graphicsitem(RPP::Module qt, RPP::Class /*cControl*/)
{
  init_point(qt); // cPointF/cPoint
  init_size(qt); // cSizeF/cSize
  init_painterpath(qt); // cPainterPath
  init_rect(); // cRectF
  init_color(qt); // cColor, cDynamicColor
  init_brush(qt); // cBrush
  init_pen(qt); // cPen
  cGraphicsItem = qt.define_class("GraphicsItem", cNoQtControl);
  cGraphicsItem.define_private_method("mark_ownership", cGraphicsItem_mark_ownership)
	       .define_method("delete", cGraphicsItem_delete)
	       .define_method("parent_get", cGraphicsItem_parent_get)
	       .define_method("parent=", cGraphicsItem_parent_set)
	       .define_method("enqueue_children", cGraphicsItem_enqueue_children)
	       .define_method("objectName_get", cGraphicsItem_objectName_get)
	       .define_method("objectName=", cGraphicsItem_objectName_set)
	       .define_method("pos=", cGraphicsItem_pos_set)
	       .define_method("pos_get", cGraphicsItem_pos_get)
	       ;
  cGraphicsItem.call("attr_dynamic", cPointF, RPP::Symbol("pos"));
  init_abstractgraphicsshapeitem(qt);
  init_synthitem(qt);
  return cGraphicsItem;
};

} // namespace R_Qt 
