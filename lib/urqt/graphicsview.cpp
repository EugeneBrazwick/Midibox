
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

//#define TRACE

#include <QtWidgets/QGraphicsView>
#include "application.h"
#include "graphicsitem.h"

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

static VALUE
cGraphicsView_scene_get(VALUE v_self)
{
  track1("%s::scene_get", v_self);
  RQTDECLSELF(QGraphicsView);
  return qt2v(self->scene());
}

static VALUE
cGraphicsView_initialize(int argc, VALUE *argv, VALUE v_self)
{
  rb_call_super(argc, argv); 
  RQTDECLSELF(QGraphicsView);
  self->setRenderHints(QPainter::Antialiasing | QPainter::SmoothPixmapTransform
		       | QPainter::HighQualityAntialiasing);
  return Qnil;
}

static void
calc_matrix(VALUE v_self)
{
  QTransform i;
  const VALUE v_rotation = rb_iv_get(v_self, "@rotation");
  if (!NIL_P(v_rotation))
    i.rotate(NUM2DBL(v_rotation)); // ccw 
  const VALUE v_scale = rb_iv_get(v_self, "@scale");
  if (!NIL_P(v_scale))
    {
      /*
      if (!rb_obj_is_instance_of(cSizeF))
	rb_raise(rb_eTypeError, "bad value %s for scaling", INSPECT(scale));
	*/
      const QSizeF &scale = v2sz(v_scale);
      i.scale(scale.width(), scale.height());
    }
  const VALUE v_translation = rb_iv_get(v_self, "@translation");
  if (!NIL_P(v_translation))
    {
      const QPointF &translation = v2pt(v_translation);
      i.translate(translation.x(), translation.y());
    }
  RQTDECLSELF(QGraphicsView);
  self->setTransform(i);
}

static VALUE
cGraphicsView_scale_set(int argc, VALUE *argv, VALUE v_self)
{
  rb_iv_set(v_self, "@scale", cSizeFWrap(args2QSizeF(argc, argv))); 
  calc_matrix(v_self);
  return Qnil;
}

static VALUE
cGraphicsView_scale_get(VALUE v_self)
{
  return rb_iv_get(v_self, "@scale");
}

void
init_graphicsview(VALUE mQt, VALUE cWidget)
{
  trace1("init_graphicsview, define R::Qt::GraphicsView, mQt=%p", (void *)mQt);
  const VALUE cGraphicsView = rb_define_class_under(mQt, "GraphicsView", cWidget);
  rb_define_alloc_func(cGraphicsView, cGraphicsView_alloc);
  rb_define_private_method(cGraphicsView, "initialize", 
			   RUBY_METHOD_FUNC(cGraphicsView_initialize), -1);
  rb_define_method(cGraphicsView, "scene=", RUBY_METHOD_FUNC(cGraphicsView_scene_set), 1);
  rb_define_method(cGraphicsView, "scene_get", RUBY_METHOD_FUNC(cGraphicsView_scene_get), 0);
  rb_define_method(cGraphicsView, "scale=", RUBY_METHOD_FUNC(cGraphicsView_scale_set), -1);
  rb_define_method(cGraphicsView, "scale_get", RUBY_METHOD_FUNC(cGraphicsView_scale_get), 0);
  rb_funcall(cGraphicsView, rb_intern("attr_dynamic"), 2, cSizeF, CSTR2SYM("scale"));
} // init_graphicsview

} // namespace R_Qt 
