
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

//#define TRACE

#include <QtWidgets/QGraphicsView>
#include "application.h"
#include "graphicsitem.h"
#include "frame.h"
#include "size.h"
#include "point.h"
#include "ruby++/numeric.h"

namespace R_Qt {

R_QT_DEF_ALLOCATOR(GraphicsView)

static VALUE
cGraphicsView_scene_set(VALUE v_self, VALUE v_scene)
{
  track2("cGraphicsView_scene_set(self=%s,scene=%s)", v_self, v_scene);
  const RPP::QObject<QGraphicsView> self = v_self;
  const RPP::QObject<QGraphicsScene> scene = v_scene;
  self->setScene(scene);
  return scene;
}

static VALUE
cGraphicsView_scene_get(VALUE v_self)
{
  track1("%s::scene_get", v_self);
  const RPP::QObject<QGraphicsView> self = v_self;
  return qt2v(self->scene());
}

static VALUE
cGraphicsView_initialize(int argc, VALUE *argv, VALUE v_self)
{
  rb_call_super(argc, argv); 
  const RPP::QObject<QGraphicsView> self = v_self;
  self->setRenderHints(QPainter::Antialiasing | QPainter::SmoothPixmapTransform
		       | QPainter::HighQualityAntialiasing);
  return Qnil;
}

static void
calc_matrix(RPP::QObject<QGraphicsView> self)
{
  QTransform i;
  const RPP::Float rotation = self.iv("@rotation");
  if (rotation.test())
    i.rotate(rotation); // ccw 
  const RPP::QSizeF scale(self.iv("@scale"), RPP::UNSAFE);
  if (scale.test())
    i.scale(scale->width(), scale->height());
  const RPP::Object translation = self.iv("@translation");
  if (translation.test())
    {
      const QPointF &t = v2pt(translation);
      i.translate(t.x(), t.y());
    }
  self->setTransform(i);
}

static VALUE
cGraphicsView_scale_set(int argc, VALUE *argv, VALUE v_self)
{
  const RPP::QObject<QGraphicsView> self = v_self;
  self.iv_set("@scale", RPP::QSizeF(argc, argv));
  calc_matrix(self);
  return Qnil;
}

void
init_graphicsview(RPP::Module qt, RPP::Class)
{
  trace1("init_graphicsview, define R::Qt::GraphicsView, mQt=%p", &qt);
  const RPP::Class cGraphicsView = qt.define_class("GraphicsView", cAbstractScrollArea);
  cGraphicsView.define_alloc_func(cGraphicsView_alloc)
	       .define_private_method("initialize", cGraphicsView_initialize)
	       .define_method("scene=", cGraphicsView_scene_set)
	       .define_method("scene_get", cGraphicsView_scene_get)
	       .define_method("scale=", cGraphicsView_scale_set)
	       ;
} // init_graphicsview

} // namespace R_Qt 
