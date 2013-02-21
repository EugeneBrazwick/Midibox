
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

//#define TRACE

#include <QtWidgets/QGraphicsView>
#include "application.h"
#include "graphicsitem.h"
#include "brush.h"
#include "ruby++/rppstring.h"
#include "ruby++/array.h"

namespace R_Qt {

RPP::Class 
cGraphicsScene;

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
  const RPP::QObject<QGraphicsScene> self = v_self;
  const RPP::QGraphicsItem<QGraphicsItem> item = v_item;
  trace2("item(%p).childItems.count= %d", &item, item->childItems().count());
  traqt1("%s::addItem", self.qtclass());
  self->addItem(item);
  // Technically v_item could be toplevel in another scene, or it could be not 
  // a toplevel at all.
  const RPP::QObject<QGraphicsScene> old_parent(item.iv("@parent"), RPP::UNSAFE);
  if (old_parent.test())
    old_parent->removeItem(item);
  trace("assign @parent in item");
  item.iv_set("@parent", self); // otherwise they lack this
  return self;
}

static VALUE
cGraphicsScene_enqueue_children(int argc, VALUE *argv, VALUE v_self)
{
  VALUE v_queue;
  rb_scan_args(argc, argv, "01", &v_queue);
  trace("cGraphicsScene_enqueue_children");
  const RPP::QObject<QGraphicsScene> self = v_self;
  self.super(v_queue);
  const bool yield = NIL_P(v_queue);
  foreach (QGraphicsItem *child, self->items())
    {
      trace3("yield=%d, item(%p).childItems.count= %d", yield, child, child->childItems().count());
      const RPP::Object v_child = item2v(child);
      if (yield)
	{
	  if (!v_child.isNil()) v_child.yield();
	}
      else
	{
	  const RPP::Array queue = v_queue;
	  if (v_child.isNil())
	      queue.push(Data_Wrap_Struct(cSynthItem, 0, 0, child));
	  else
	    {
	      trace("add child to v_queue");
	      trace3("yield=%d, item(%p).childItems.count= %d", yield, child, child->childItems().count());
	      queue.push(v_child);
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
  const RPP::QObject<QGraphicsScene> self = v_self;
  self.check_frozen();
  self->setSceneRect(args2QRectF(argc, argv));
  return Qnil;
}

static VALUE
cGraphicsScene_sceneRect_get(VALUE v_self)
{
  const RPP::QObject<QGraphicsScene> self = v_self;
  // We cannot Wrap just &self->sceneRect() as it is a temporary...
  return cRectFWrap(new QRectF(self->sceneRect()));
}

static VALUE
cGraphicsScene_backgroundBrush_set(VALUE v_self, VALUE v_brush)
{
  const RPP::QObject<QGraphicsScene> self = v_self;
  const RPP::QBrush brush = v_brush;
  self.iv_set("@brush", brush);
  self->setBackgroundBrush(*brush);
  return brush;
}

void
init_graphicsscene(RPP::Module qt, RPP::Class control)
{
  trace("init_graphicsscene()");
  cGraphicsScene = qt.define_class("GraphicsScene", control);
  cGraphicsScene.define_alloc_func(cGraphicsScene_alloc)
		.define_method("addItem", cGraphicsScene_addItem)
		.define_method("sceneRect=", cGraphicsScene_sceneRect_set)
		.define_method("sceneRect_get", cGraphicsScene_sceneRect_get)
		.define_method("enqueue_children", cGraphicsScene_enqueue_children)
		.define_method("backgroundBrush=", cGraphicsScene_backgroundBrush_set)
		;
}

} // namespace R_Qt 
