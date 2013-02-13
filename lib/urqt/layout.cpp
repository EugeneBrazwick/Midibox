
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

//#define TRACE

#pragma implementation
#include "layout.h"
#include <QtWidgets/QHBoxLayout>
#include <QtWidgets/QVBoxLayout>
#include <QtWidgets/QWidget>
#include <QtWidgets/QGridLayout>
#include "application.h"
#include "widget.h"

namespace R_Qt {

VALUE
cLayout = Qnil;

static VALUE
cBoxLayout_addLayout(VALUE v_self, VALUE v_layout)
{
  RQTDECLSELF(QBoxLayout);
  RQTDECLARE(QLayout, layout);
  self->addLayout(layout);
  return v_self;
}

R_QT_DEF_ALLOCATOR(HBoxLayout)
R_QT_DEF_ALLOCATOR(VBoxLayout)

static void
init_boxlayout(VALUE mQt, VALUE cLayout)
{
  const VALUE cBoxLayout = rb_define_class_under(mQt, "BoxLayout", cLayout);
  rb_define_method(cBoxLayout, "addLayout", RUBY_METHOD_FUNC(cBoxLayout_addLayout), 1);
  const VALUE cVBox = rb_define_class_under(mQt, "VBoxLayout", cBoxLayout);
  rb_define_alloc_func(cVBox, cVBoxLayout_alloc);
  const VALUE cHBox = rb_define_class_under(mQt, "HBoxLayout", cBoxLayout);
  rb_define_alloc_func(cHBox, cHBoxLayout_alloc);
}

R_QT_DEF_ALLOCATOR(GridLayout)

static VALUE
cGridLayout_columnCount(int argc, VALUE *argv, VALUE v_self)
{
  if (argc == 0)
    {
      const VALUE r = rb_iv_get(v_self, "@columnCount");
      if (RTEST(r)) return r;
      RQTDECLSELF(QGridLayout);
      return INT2NUM(self->columnCount());
    }
  VALUE v_columnCount;
  rb_scan_args(argc, argv, "1", &v_columnCount);
  rb_iv_set(v_self, "@columnCount", v_columnCount); 
  return v_columnCount;
}

static VALUE
cGridLayout_initialize(int argc, VALUE *argv, VALUE v_self)
{
  rb_call_super(argc, argv);
  rb_iv_set(v_self, "currow", INT2NUM(0));
  rb_iv_set(v_self, "curcol", INT2NUM(0));
  return Qnil;
}

#define GRIDLAYOUT_ADD(X) \
static VALUE \
cGridLayout_add##X(VALUE v_self, VALUE v_x) \
{ \
  RQTDECLSELF(QGridLayout); \
  RQTDECLARE(Q##X, x); \
  int currow = NUM2INT(rb_iv_get(v_self, "currow")); \
  const int currow_org = currow; \
  int curcol = NUM2INT(rb_iv_get(v_self, "curcol")); \
  const int columnCount = NUM2INT(rb_funcall(v_self, rb_intern("columnCount"), 0)); \
  self->add##X(x, currow, curcol); \
  if (++curcol == columnCount) \
    { \
      currow++; \
      curcol = 0; \
    } \
  rb_iv_set(v_self, "curcol", INT2NUM(curcol)); \
  if (currow_org != currow) \
    rb_iv_set(v_self, "currow", INT2NUM(currow)); \
  rb_iv_set(v_x, "@parent", v_self); /* see cLayout_addWidget */ \
  return v_self; \
}

GRIDLAYOUT_ADD(Widget)
GRIDLAYOUT_ADD(Layout)

static void
init_gridlayout(VALUE mQt, VALUE cLayout)
{
  const VALUE cGridLayout = rb_define_class_under(mQt, "GridLayout", cLayout);
  rb_define_alloc_func(cGridLayout, cGridLayout_alloc);
  rb_define_method(cGridLayout, "columnCount", RUBY_METHOD_FUNC(cGridLayout_columnCount), -1);
  rb_define_alias(cGridLayout, "columncount", "columnCount");
  rb_define_alias(cGridLayout, "colcount", "columnCount");
  rb_define_alias(cGridLayout, "columns", "columnCount");
  rb_define_private_method(cGridLayout, "initialize", 
			   RUBY_METHOD_FUNC(cGridLayout_initialize), -1);
  rb_define_method(cGridLayout, "addWidget", RUBY_METHOD_FUNC(cGridLayout_addWidget), 1);
  rb_define_method(cGridLayout, "addLayout", RUBY_METHOD_FUNC(cGridLayout_addLayout), 1);
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
  trace1("cLayout_enqueue_children, yieldmode=%d", NIL_P(v_queue));
  rb_call_super(1, &v_queue);
  RQTDECLSELF(QLayout);
  const int N = self->count();
  trace2("%s::enqueue_childitems, N = %d", TO_CSTR(v_self), N);
  const bool yield = NIL_P(v_queue);
  for (int i = 0; i < N; i++)
    {
      QWidget * const w = self->itemAt(i)->widget();
      trace2("i=%d, w=%p", i, w);
      if (!w) continue; // ignore spacers
      const VALUE v_child = qt2v(w);
      trace3("got class %s, name '%s', v_child=%s", QTCLASS(w), qString2cstr(w->objectName()), INSPECT(v_child));
      if (yield)
	{
	  if (!NIL_P(v_child)) 
	    {
	      trace("YIELD widget");
	      rb_yield(v_child);
	    }
	}
      else
	{
	  Check_Type(v_queue, T_ARRAY);
	  if (NIL_P(v_child)) 
	    rb_ary_push(v_queue, Data_Wrap_Struct(cSynthObject, 0, 0, w));
	  else
	    rb_ary_push(v_queue, v_child);
	}
    }
  return Qnil;
} // cLayout_enqueue_children

void
init_layout(VALUE mQt, VALUE cControl)
{
  trace("init_layout");
  cLayout = rb_define_class_under(mQt, "Layout", cControl);
  rb_define_method(cLayout, "addWidget", RUBY_METHOD_FUNC(cLayout_addWidget), 1);
  rb_define_protected_method(cLayout, "enqueue_children", 
			     RUBY_METHOD_FUNC(cLayout_enqueue_children), 1);
  init_boxlayout(mQt, cLayout);
  init_gridlayout(mQt, cLayout);
}

} // namespace R_Qt
