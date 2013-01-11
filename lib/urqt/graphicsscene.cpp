
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

#define TRACE

#include <QtWidgets/QGraphicsView>
#include "application.h"

namespace R_Qt {

/*  This was of course, far too easy
 *
 * The ruby object now does illegal casts to QWidget,
 * because we inherit cWidget, and RQTDECLSELF is NOT typesafe.
 */
R_QT_DEF_ALLOCATOR(GraphicsScene)

void
init_graphicsscene(VALUE mQt, VALUE cControl)
{
  trace1("init_graphicsscene, define R::Qt::GraphicsScene, mQt=%p", (void *)mQt);
  const VALUE cGraphicsScene = rb_define_class_under(mQt, "GraphicsScene", cControl);
  rb_define_alloc_func(cGraphicsScene, cGraphicsScene_alloc);
}

} // namespace R_Qt 
