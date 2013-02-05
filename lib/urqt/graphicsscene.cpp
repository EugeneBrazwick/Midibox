
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

//#define TRACE

#include <QtWidgets/QGraphicsView>
#include "application.h"
#include "graphicsitem.h"
#include "brush.h"

namespace R_Qt {

VALUE 
cGraphicsScene = Qnil;

/* NOTE: _mark methods may NOT allocate or free ruby values.
 * This includes TO_CSTR debug statements.
 */
void
cGraphicsScene_mark(QGraphicsScene *object)
{
  trace("cGraphicsScene_mark");
  cObject_mark(object);
  foreach (QGraphicsItem *child, object->items())
    {
      const VALUE vChild = item2v(child);
      if (!NIL_P(vChild)) rb_gc_mark(vChild);
    }
}

static VALUE
cGraphicsSceneWrap(QGraphicsScene *object)
{
  trace1("cGraphicsSceneWrap(%p)", object);
  return Data_Wrap_Struct(cGraphicsScene, cGraphicsScene_mark, 0, object);
}

R_QT_DEF_ALLOCATOR_BASE1(GraphicsScene)

static VALUE
cGraphicsScene_addItem(VALUE v_self, VALUE v_item)
{
  track2("cGraphicsScene_addItem(%s, %s)", v_self, v_item);
  RQTDECLSELF(QGraphicsScene);
  RQTDECLARE_GI(QGraphicsItem, item);
  trace2("item(%p).childItems.count= %d", item, item->childItems().count());
  traqt1("%s::addItem", QTCLASS(self));
  self->addItem(item);
  // Technically v_item could be toplevel in another scene, or it could be not 
  // a toplevel at all.
  VALUE v_old_parent = rb_iv_get(v_item, "@parent");
  if (!NIL_P(v_old_parent))
    {
      RQTDECLARE(QGraphicsScene, old_parent);
      traqt1("%s::addItem", QTCLASS(old_parent));
      old_parent->removeItem(item);
    }
  trace("assign @parent in item");
  rb_iv_set(v_item, "@parent", v_self); // otherwise they lack this
  return v_self;
}

static VALUE
cGraphicsScene_parent_set(VALUE v_self, VALUE v_parent)
{
  trace("cGraphicsScene_parent_set");
  return rb_funcall(v_parent, rb_intern("addScene"), 1, v_self);
}

static VALUE
cGraphicsScene_addObject(VALUE /*v_self*/, VALUE /*v_child*/)
{
  trace("cGraphicsScene_addObject");
  rb_raise(rb_eTypeError, "can only add GraphicsItems to a GraphicsScene");
}

static VALUE
cGraphicsScene_children(VALUE v_self)
{
  trace("cGraphicsScene_children");
  return rb_funcall(rb_funcall(v_self, rb_intern("each_child"), 0),
		    rb_intern("to_a"), 0);
}

static VALUE
cGraphicsScene_enqueue_children(VALUE v_self, VALUE v_queue)
{
  trace("cGraphicsScene_enqueue_children");
  RQTDECLSELF(QGraphicsScene);
  rb_call_super(1, &v_queue);
  const bool yield = NIL_P(v_queue);
  foreach (QGraphicsItem *child, self->items())
    {
      trace3("yield=%d, item(%p).childItems.count= %d", yield, child, child->childItems().count());
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
	      rb_ary_push(v_queue, Data_Wrap_Struct(cSynthItem, 0, 0, child));
	  else
	    {
	      trace("add child to v_queue");
	      trace3("yield=%d, item(%p).childItems.count= %d", yield, child, child->childItems().count());
	      rb_ary_push(v_queue, v_child);
	    }
	}
    }
  return Qnil;
}

/** :call-seq:
 *    area w
 *    area w, h
 *    area size
 *    area x, y, w, h
 *    area rect
 * 
 * x and y default to 0.
 * height defaults to width.
 */
static VALUE
cGraphicsScene_sceneRect_set(int argc, VALUE *argv, VALUE v_self)
{
  RQTDECLSELF(QGraphicsScene);
  trace("calling args2QRectF");
  const QRectF &rect = args2QRectF(argc, argv);
  traqt1("setSceneRect(%s)", rect);
  self->setSceneRect(rect);
  return Qnil;
}

static VALUE
cGraphicsScene_sceneRect_get(VALUE v_self)
{
  RQTDECLSELF(QGraphicsScene);
  // We cannot Wrap just &self->sceneRect() as it is a temporary...
  return cRectFWrap(new QRectF(self->sceneRect()));
}

static VALUE
cGraphicsScene_backgroundBrush_set(VALUE v_self, VALUE v_brush)
{
  rb_iv_set(v_self, "@brush", v_brush);
  RQTDECLSELF(QGraphicsScene);
  RQTDECLARE_BRUSH(brush);
  track2("%s.brush_set(%s)", v_self, v_brush);
  traqt1("::setBackgroundBrush", QTCLASS(self));
  self->setBackgroundBrush(*brush);
  return v_brush;
}

static VALUE
cGraphicsScene_backgroundBrush_get(VALUE v_self)
{
  return rb_iv_get(v_self, "@brush");
}

static VALUE
cGraphicsScene_backgroundBrush(int argc, VALUE *argv, VALUE v_self)
{
  if (argc == 0)
    return cGraphicsScene_backgroundBrush_get(v_self);
  VALUE argv_ex[argc + 1];
  argv_ex[0] = v_self;
  memcpy(argv_ex + 1, argv, argc * sizeof(VALUE));
  return rb_funcall_passing_block(cBrush, rb_intern("new"), argc + 1, argv_ex);
}

void
init_graphicsscene(VALUE mQt, VALUE cControl)
{
  trace1("init_graphicsscene, define R::Qt::GraphicsScene, mQt=%p", (void *)mQt);
  cGraphicsScene = rb_define_class_under(mQt, "GraphicsScene", cControl);
  rb_define_alloc_func(cGraphicsScene, cGraphicsScene_alloc);
  rb_define_method(cGraphicsScene, "addItem", RUBY_METHOD_FUNC(cGraphicsScene_addItem), 1);
  rb_define_method(cGraphicsScene, "addObject", RUBY_METHOD_FUNC(cGraphicsScene_addObject), 1);
  rb_define_method(cGraphicsScene, "parent=", RUBY_METHOD_FUNC(cGraphicsScene_parent_set), 1);
  rb_define_method(cGraphicsScene, "sceneRect=", RUBY_METHOD_FUNC(cGraphicsScene_sceneRect_set), -1);
  rb_define_method(cGraphicsScene, "sceneRect_get", RUBY_METHOD_FUNC(cGraphicsScene_sceneRect_get), 0);
  rb_define_method(cGraphicsScene, "children", RUBY_METHOD_FUNC(cGraphicsScene_children), 0);
  rb_define_method(cGraphicsScene, "enqueue_children", 
		   RUBY_METHOD_FUNC(cGraphicsScene_enqueue_children), 1);
  rb_define_alias(cGraphicsScene, "addGraphicsItem", "addItem");
  rb_funcall(cGraphicsScene, rb_intern("attr_dynamic"), 2, cRectF, CSTR2SYM("sceneRect"));
  rb_define_alias(cGraphicsScene, "area", "sceneRect");
  rb_define_method(cGraphicsScene, "backgroundBrush=", 
		   RUBY_METHOD_FUNC(cGraphicsScene_backgroundBrush_set), 1);
  rb_define_method(cGraphicsScene, "backgroundBrush_get", 
		   RUBY_METHOD_FUNC(cGraphicsScene_backgroundBrush_get), 0);
  rb_define_method(cGraphicsScene, "backgroundBrush", 
		   RUBY_METHOD_FUNC(cGraphicsScene_backgroundBrush), -1);
  rb_define_alias(cGraphicsScene, "background", "backgroundBrush");
  // the next one makes life easier for brush.cpp
  rb_define_alias(cGraphicsScene, "brush=", "backgroundBrush=");
}

} // namespace R_Qt 
