
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

//#define TRACE

#pragma implementation
#include "graphicsitem.h"
#include "brush.h"
#include "object.h"
#include <assert.h>
#include <QtGui/QBrush>

namespace R_Qt {

VALUE 
cRectF = Qnil, cPen = Qnil;

VALUE
cGraphicsItem = Qnil, cAbstractGraphicsShapeItem = Qnil;

void
cRectF_free(QRectF *rect)
{
  trace1("cRectF_free(%p)", rect);
  traqt1("delete QRectF %p", rect);
  delete rect;
}

R_QT_DEF_ALLOCATOR_BASE1(RectF)

static void 
init_rect(VALUE mQt)
{
  cRectF = rb_define_class_under(mQt, "Rectangle", rb_cObject);
  rb_define_alloc_func(cRectF, cRectF_alloc);
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
      assert(var.canConvert<RValue>());
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

static void 
cGraphicsItem_delete(VALUE v_self)
{
  trace1("cGraphicsItem_delete, zombified=%d", IS_ZOMBIFIED(v_self));
  if (IS_ZOMBIFIED(v_self)) return;
  RQTDECLSELF_GI(QGraphicsItem);
  trace1("DELETE QGraphicsItem %p", self);
  zombify(self);
  traqt1("delete QGraphicsItem(%p)", self);
  delete self;
}

static VALUE 
cGraphicsItem_parent_set(VALUE v_self, VALUE v_parent)
{
  track2("%s::parent_set(%s)", v_self, v_parent);
  rb_check_frozen(v_self);
  QGraphicsItem *parent = 0;
  if (!NIL_P(v_parent))
    GET_STRUCT_NODECL(QGraphicsItem, parent);
  trace("retrieve self");
  RQTDECLSELF_GI(QGraphicsItem);
  traqt("QGraphicsItem::setParentItem");
  self->setParentItem(parent);
  return v_parent;
}

static VALUE
cGraphicsItem_objectName_set(VALUE v_self, VALUE v_newname)
{
  rb_check_frozen(v_self);
  RQTDECLSELF_GI(QGraphicsItem);
  traqt("QGraphicsItem::setData");
  self->setData(R_QT_NAME_GI_KEY, QVariant::fromValue(RValue(v_newname)));
  return v_newname;
}

static VALUE
cGraphicsItem_objectName_get(VALUE v_self)
{
  RQTDECLSELF_GI(QGraphicsItem);
  const QVariant &var = self->data(R_QT_NAME_GI_KEY);
  return *var.value<RValue>();
}

static VALUE
cGraphicsItem_parent_get(VALUE v_self)
{
  trace("cGraphicsItem_parent_get");
  VALUE v_parent = rb_iv_get(v_self, "@parent");
  if (!NIL_P(v_parent)) return v_parent;
  RQTDECLSELF_GI(QGraphicsItem);
  traqt("QGraphicsItem::parentItem");
  return item2v(self->parentItem());
}

static VALUE 
cGraphicsItem_enqueue_children(VALUE v_self, VALUE v_queue)
{
  trace("cGraphicsItem_enqueue_children");
  track2("%s::enqueue_children(%s)", v_self, v_queue);
  RQTDECLSELF_GI(QGraphicsItem);
  traqt("childItems");
  trace1("self = %p", self);
  trace2("self = %p, parentItem = %p, calling childItems()", self, self->parentItem());
  const QList<QGraphicsItem*> &children = self->childItems();
  trace1("#children = %d", children.count());
  const bool yield = NIL_P(v_queue);
  foreach (QGraphicsItem *child, children)
    {
      const VALUE v_child = item2v(child);
      if (yield)
	{
	  if (!NIL_P(v_child)) 
	    rb_yield(v_child);
	}
      else
	{
	  Check_Type(v_queue, T_ARRAY);
	  if (NIL_P(v_child)) 
	    rb_ary_push(v_queue, Data_Wrap_Struct(cGraphicsItem, 0, 0, child));
	  else
	    rb_ary_push(v_queue, v_child);
	}
    }
  return Qnil;
}

static VALUE
cGraphicsItem_connect(VALUE /*v_self*/, VALUE v_signal, VALUE v_proc)
{
  if (TYPE(v_signal) != T_SYMBOL) rb_raise(rb_eTypeError, "GraphicItems only support ruby signals");
  VALUE v_args[2] = { v_signal, v_proc };
  return rb_call_super(2, v_args);
}

static VALUE
cGraphicsItem_emit(int argc, VALUE *argv, VALUE /*v_self*/)
{
  VALUE v_signal, v_args;
  rb_scan_args(argc, argv, "1*", &v_signal, &v_args);
  if (TYPE(v_signal) != T_SYMBOL) rb_raise(rb_eTypeError, "GraphicItems only support ruby signals");
  return rb_call_super(argc, argv);
}

static VALUE
cAbstractGraphicsShapeItem_brush_set(VALUE v_self, VALUE v_brush)
{
  rb_iv_set(v_self, "@brush", v_brush);
  RQTDECLSELF_GI(QAbstractGraphicsShapeItem);
  RQTDECLARE_BRUSH(brush);
  track2("%s.brush_set(%s)", v_self, v_brush);
  traqt1("::setBrush", QTCLASS(self));
  self->setBrush(*brush);
  return v_brush;
}

static VALUE
cAbstractGraphicsShapeItem_brush_get(VALUE v_self)
{
  return rb_iv_get(v_self, "@brush");
}

static VALUE
cAbstractGraphicsShapeItem_enqueue_children(VALUE v_self, VALUE v_queue)
{
  rb_call_super(1, &v_queue);
  const bool yield = NIL_P(v_queue);
  VALUE v_brush = rb_iv_get(v_self, "@brush");
  if (!NIL_P(v_brush))
    {
      if (yield) 
	  rb_yield(v_brush);
      else
	{
	  Check_Type(v_queue, T_ARRAY);
	  rb_ary_push(v_queue, v_brush);
	}
    }
  return Qnil;
}

static void
init_abstractgraphicsshapeitem(VALUE mQt)
{
  cAbstractGraphicsShapeItem = rb_define_class_under(mQt, "AbstractGraphicsShapeItem", cGraphicsItem);
  rb_define_method(cAbstractGraphicsShapeItem, "brush=", 
		   RUBY_METHOD_FUNC(cAbstractGraphicsShapeItem_brush_set), 1);
  rb_define_method(cAbstractGraphicsShapeItem, "brush_get", 
		   RUBY_METHOD_FUNC(cAbstractGraphicsShapeItem_brush_get), 0);
  rb_define_method(cAbstractGraphicsShapeItem, "enqueue_children", 
		   RUBY_METHOD_FUNC(cAbstractGraphicsShapeItem_enqueue_children), 1);
  /* STUPID IDEA rb_define_attr(cAbstractGraphicsShapeItem, "brush", true/r/, false/w/); 
   * */
}

VALUE
init_graphicsitem(VALUE mQt, VALUE /*cControl*/)
{
  init_rect(mQt);
  init_brush(mQt);
  init_color(mQt);
  cGraphicsItem = rb_define_class_under(mQt, "GraphicsItem", cNoQtControl);
  rb_define_private_method(cGraphicsItem, "mark_ownership", 
			   RUBY_METHOD_FUNC(cGraphicsItem_mark_ownership), 0);
  rb_define_method(cGraphicsItem, "delete", RUBY_METHOD_FUNC(cGraphicsItem_delete), 0);
  rb_define_method(cGraphicsItem, "parent_get", RUBY_METHOD_FUNC(cGraphicsItem_parent_get), 0);
  rb_define_method(cGraphicsItem, "parent=", RUBY_METHOD_FUNC(cGraphicsItem_parent_set), 1);
  rb_define_method(cGraphicsItem, "enqueue_children", 
		   RUBY_METHOD_FUNC(cGraphicsItem_enqueue_children), 1);
  rb_define_method(cGraphicsItem, "objectName_get", RUBY_METHOD_FUNC(cGraphicsItem_objectName_get), 0);
  rb_define_method(cGraphicsItem, "objectName=", RUBY_METHOD_FUNC(cGraphicsItem_objectName_set), 1);
  rb_define_method(cGraphicsItem, "delete", RUBY_METHOD_FUNC(cGraphicsItem_delete), 0);
  rb_define_private_method(cGraphicsItem, "connect", RUBY_METHOD_FUNC(cGraphicsItem_connect), 2);
  rb_define_private_method(cGraphicsItem, "emit", RUBY_METHOD_FUNC(cGraphicsItem_emit), -1);
  init_abstractgraphicsshapeitem(mQt);
  return cGraphicsItem;
};

} // namespace R_Qt 
