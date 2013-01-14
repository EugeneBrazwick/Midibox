
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

//#define TRACE

#include <QtWidgets/QGraphicsView>
#include "application.h"

namespace R_Qt {

R_QT_DEF_ALLOCATOR(GraphicsView)

static VALUE
cGraphicsView_scene_set(VALUE v_self, VALUE v_scene)
{
  track2("cGraphicsView_scene_set(self=%s,scene=%s)", v_self, v_scene);
  RQTDECLSELF(QGraphicsView);
  RQTDECLARE(QGraphicsScene, scene);
  traqt2("%s::setScene(%s)", QTCLASS(self), QTCLASS(scene));
  self->setScene(scene);
  return v_scene;
}

void
init_graphicsview(VALUE mQt, VALUE cWidget)
{
  trace1("init_graphicsview, define R::Qt::GraphicsView, mQt=%p", (void *)mQt);
  const VALUE cGraphicsView = rb_define_class_under(mQt, "GraphicsView", cWidget);
  rb_define_alloc_func(cGraphicsView, cGraphicsView_alloc);
  rb_define_method(cGraphicsView, "scene=", RUBY_METHOD_FUNC(cGraphicsView_scene_set), 1);
} // init_graphicsview
} // namespace R_Qt 
