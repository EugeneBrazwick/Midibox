
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

//#define TRACE

#pragma implementation
#include "graphicsitem.h"
#include "api_utils.h"
#include "object.h"
#include <assert.h>

namespace R_Qt {

VALUE 
cRectF = Qnil;

VALUE
cGraphicsItem = Qnil;

void
cRectF_free(QRectF *rect)
{
  trace1("cRectF_free(%p)", rect);
  traqt1("delete QRectF %p", rect);
  delete rect;
}

R_QT_DEF_ALLOCATOR_BASE(RectF, RectF)

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
  trace2("item2v(%p) -> INSPECT -> %s", i, INSPECT(rv)); 
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

static VALUE
cGraphicsItem_initialize(int argc, VALUE *argv, VALUE v_self)
{
#if defined(DEBUG)
  QGraphicsItem * const self = 
#endif
			       v2item(v_self); // First mark ownership
#if defined(DEBUG)
  const VALUE vdbg = item2v(self);
  assert(vdbg == v_self);
#endif
  //trace("scan args and assign parent");
  VALUE v_0, v_1, v_2;
  rb_scan_args(argc, argv, "03", &v_0, &v_1, &v_2);
  if (!NIL_P(v_0))
    {
      cObject_initialize_arg(v_self, v_0);
      if (!NIL_P(v_1))
	{
	  cObject_initialize_arg(v_self, v_1);
	  if (!NIL_P(v_2))
	    cObject_initialize_arg(v_self, v_2);
	}
    }
  if (rb_block_given_p())
    rb_obj_instance_eval(0, 0, v_self);
  return Qnil;
}

static void 
cGraphicsItem_delete(VALUE v_self)
{
  if (IS_ZOMBIFIED(v_self)) return;
  RQTDECLSELF_GI(QGraphicsItem);
  zombify(self);
  traqt1("delete QGraphicsItem(%p)", self);
  delete self;
}

static VALUE 
cGraphicsItem_parent_set(VALUE v_self, VALUE v_parent)
{
  trace("cGraphicsItem_parent_set");
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
cGraphicsItem_parent(int argc, VALUE *argv, VALUE v_self)
{
  trace("cObject_parent");
  RQTDECLSELF_GI(QGraphicsItem);
  if (argc == 0) 
    {
      traqt("QGraphicsItem::parentItem");
      return item2v(self->parentItem());
    }
  VALUE v_new_parent;
  rb_scan_args(argc, argv, "1", &v_new_parent);
  return cGraphicsItem_parent_set(v_self, v_new_parent);
}

static VALUE
cGraphicsItem_children(int argc, VALUE *argv, VALUE v_self)
{
  RQTDECLSELF_GI(QGraphicsItem);
  traqt("QGraphicsItem::childItems");
  const QList<QGraphicsItem*>&children = self->childItems();
  if (argc == 0)
    {
      const VALUE r = rb_ary_new2(children.count());
      foreach (QGraphicsItem *child, children) // foreach is delete/remove-safe!
	{
	  const VALUE v_child = item2v(child);
	  if (!NIL_P(v_child)) rb_ary_push(r, v_child);
	}
      return r;
    }
  rb_check_frozen(v_self);
  VALUE v_children;
  rb_scan_args(argc, argv, "*", &v_children);
  VALUE v_t = RARRAY_LEN(v_children) == 1 ? rb_check_array_type(rb_ary_entry(v_children, 0)) 
					  : Qnil;
  if (RTEST(v_t)) v_children = v_t;
  foreach (QGraphicsItem *child, children)
    child->setParentItem(0);
  const long N = RARRAY_LEN(v_children);
  long i = 0;
  for (VALUE *v_child = RARRAY_PTR(v_children); i < N; i++, v_child++)
    {
      if (!rb_obj_is_kind_of(*v_child, cGraphicsItem))
	rb_raise(rb_eTypeError, "passed child %s that was not a QGraphicsItem", TO_S(*v_child));
      trace2("i=%ld, N=%ld", i, N);
      GET_STRUCT_PTR(QGraphicsItem, child);
      traqt("QGraphicsItem::setParentItem");
      child->setParentItem(self);
    }
  return v_children;
} // cObject_children

static VALUE
cGraphicsItem_each_child(int argc, VALUE *argv, VALUE v_self)
{
  RETURN_ENUMERATOR(v_self, argc, argv);
  RQTDECLSELF_GI(QGraphicsItem);
  traqt("QGraphicsItem::childItems");
  const QList<QGraphicsItem*> &children = self->childItems();
  foreach (QGraphicsItem *child, children) // foreach is delete/remove-safe!
    {
      const VALUE v_child = item2v(child);
      if (!NIL_P(v_child)) rb_yield(v_child);
    }
  return Qnil;
} // cGraphicsItem_each_child

static VALUE
cGraphicsItem_each_child_with_root(int argc, VALUE *argv, VALUE v_self)
{
  RETURN_ENUMERATOR(v_self, argc, argv);
  rb_yield(v_self);
  RQTDECLSELF_GI(QGraphicsItem);
  traqt("QGraphicsItem::childItems");
  foreach (QGraphicsItem *child, self->childItems())
    {
      const VALUE v_child = item2v(child);
      if (!NIL_P(v_child)) rb_yield(v_child);
    }
  return Qnil;
}

static void 
enqueue_children(VALUE v_item, VALUE v_queue, int &c)
{
  GET_STRUCT(QGraphicsItem, item);
  traqt("QGraphicsItem::childItems");
  const QList<QGraphicsItem*> &children = item->childItems();
  foreach (QGraphicsItem *child, children)
    {
      const VALUE v_child = item2v(child);
      if (NIL_P(v_child)) continue;
      rb_ary_push(v_queue, v_child);
      ++c;
    }
}

static VALUE
each_sub(VALUE v_self)
{
  VALUE v_queue = rb_ary_new();
  int c = 0;
  enqueue_children(v_self, v_queue, c); 
  while (c)
    {
      VALUE v_node = rb_ary_shift(v_queue);
      --c;
      rb_yield(v_node);
      enqueue_children(v_node, v_queue, c);
    }
  return Qnil;
}

/** breadth-first search, but it excludes SELF!!!
 */
static VALUE
cGraphicsItem_each_sub(int argc, VALUE *argv, VALUE v_self)
{
  RETURN_ENUMERATOR(v_self, argc, argv);
  return each_sub(v_self);
} // cObject_each_sub

/** breadth-first search, and includes self (as first result)
 */
static VALUE
cGraphicsItem_each_sub_with_root(int argc, VALUE *argv, VALUE v_self)
{
  RETURN_ENUMERATOR(v_self, argc, argv);
  rb_yield(v_self);
  return each_sub(v_self);
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
cGraphicsItem_widget_p(VALUE /*v_self*/)
{
  return Qfalse;
}

VALUE
init_graphicsitem(VALUE mQt, VALUE cControl)
{
  init_rect(mQt);
  cGraphicsItem = rb_define_class_under(mQt, "GraphicsItem", cControl);
  // IMPORTANT overrides to hide all QObject method that actually use the Qt pointer 
  rb_define_method(cGraphicsItem, "initialize", RUBY_METHOD_FUNC(cGraphicsItem_initialize), -1);
  rb_define_method(cGraphicsItem, "delete", RUBY_METHOD_FUNC(cGraphicsItem_delete), 0);
  rb_define_method(cGraphicsItem, "parent", RUBY_METHOD_FUNC(cGraphicsItem_parent), -1);
  rb_define_method(cGraphicsItem, "parent=", RUBY_METHOD_FUNC(cGraphicsItem_parent_set), 1);
  rb_define_method(cGraphicsItem, "children", RUBY_METHOD_FUNC(cGraphicsItem_children), -1);
  rb_define_method(cGraphicsItem, "objectName_get", RUBY_METHOD_FUNC(cGraphicsItem_objectName_get), 0);
  rb_define_method(cGraphicsItem, "objectName=", RUBY_METHOD_FUNC(cGraphicsItem_objectName_set), 1);
  rb_define_method(cGraphicsItem, "delete", RUBY_METHOD_FUNC(cGraphicsItem_delete), 0);
  rb_define_method(cGraphicsItem, "widget?", RUBY_METHOD_FUNC(cGraphicsItem_widget_p), 0);
  rb_define_method(cGraphicsItem, "each_child", RUBY_METHOD_FUNC(cGraphicsItem_each_child), -1);
  rb_define_method(cGraphicsItem, "each", RUBY_METHOD_FUNC(cGraphicsItem_each_child), -1);
  rb_define_method(cGraphicsItem, "each_sub", RUBY_METHOD_FUNC(cGraphicsItem_each_sub), -1);
  rb_define_method(cGraphicsItem, "each_sub_with_root", 
		   RUBY_METHOD_FUNC(cGraphicsItem_each_sub_with_root), -1);
  rb_define_method(cGraphicsItem, "each_child_with_root", 
		   RUBY_METHOD_FUNC(cGraphicsItem_each_child_with_root), -1);
  rb_define_private_method(cGraphicsItem, "connect", RUBY_METHOD_FUNC(cGraphicsItem_connect), 2);
  rb_define_private_method(cGraphicsItem, "emit", RUBY_METHOD_FUNC(cGraphicsItem_emit), -1);
  return cGraphicsItem;
};

} // namespace R_Qt 
