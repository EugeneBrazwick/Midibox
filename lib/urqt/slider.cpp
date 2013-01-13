
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

//#define TRACE

#include <QtWidgets/QSlider>
#include "application.h"

namespace R_Qt {

R_QT_DEF_ALLOCATOR(Slider)

void
init_slider(VALUE mQt, VALUE cWidget)
{
  trace("init_slider");
  const VALUE cSlider = rb_define_class_under(mQt, "Slider", cWidget);
  rb_define_alloc_func(cSlider, cSlider_alloc);
} // init_slider
} // namespace R_Qt {
