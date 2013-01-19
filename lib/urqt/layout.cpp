
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

#define TRACE

#include <ruby/ruby.h>
#include <QtWidgets/QHBoxLayout>
#include <QtWidgets/QVBoxLayout>
#include <QtWidgets/QWidget>
#include "application.h"

namespace R_Qt {

R_QT_DEF_ALLOCATOR(HBoxLayout)
R_QT_DEF_ALLOCATOR(VBoxLayout)

static void
init_boxlayout(VALUE mQt, VALUE cLayout)
{
  const VALUE cBoxLayout = rb_define_class_under(mQt, "BoxLayout", cLayout);
  const VALUE cVBox = rb_define_class_under(mQt, "VBoxLayout", cBoxLayout);
  rb_define_alloc_func(cVBox, cVBoxLayout_alloc);
  const VALUE cHBox = rb_define_class_under(mQt, "HBoxLayout", cBoxLayout);
  rb_define_alloc_func(cHBox, cHBoxLayout_alloc);
}

static VALUE
cLayout_addWidget(VALUE v_self, VALUE v_widget)
{
  RQTDECLSELF(QLayout);
  RQTDECLARE(QWidget, widget);
  self->addWidget(widget);
  // Qt reparents the widget to widget it is itself located in
  rb_iv_set(v_widget, "@parent", v_self);
  return v_self;
}

//override
static VALUE
cLayout_enqueue_children(VALUE v_self, VALUE v_queue)
{
  rb_call_super(1, &v_queue);
  RQTDECLSELF(QLayout);
  const int N = self->count();
  trace2("%s::enqueue_children, N = %d", TO_CSTR(v_self), N);
  const bool yield = !NIL_P(v_queue);
  if (!yield)
    v_queue = to_ary(v_queue);
  for (int i = 0; i < N; i++)
    {
      QWidget * const w = self->itemAt(i)->widget();
      if (!w) continue; // ignore spacers
      if (yield)
	{
	  const VALUE v_child = qt2v(w);
	  if (!NIL_P(v_child)) 
	    rb_yield(v_child);
	}
      else
	  rb_ary_push(v_queue, Data_Wrap_Struct(cObject, 0, 0, w));
    }
  return Qnil;
} // cLayout_enqueue_children

void
init_layout(VALUE mQt, VALUE cControl)
{
  trace("init_layout");
  const VALUE cLayout = rb_define_class_under(mQt, "Layout", cControl);
  rb_define_method(cLayout, "addWidget", RUBY_METHOD_FUNC(cLayout_addWidget), 1);
  rb_define_private_method(cLayout, "enqueue_children", 
		   RUBY_METHOD_FUNC(cLayout_enqueue_children), 1);
  init_boxlayout(mQt, cLayout);
}

} // namespace R_Qt
