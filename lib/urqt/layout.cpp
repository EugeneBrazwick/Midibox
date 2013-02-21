
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
#include "ruby++/array.h"

namespace R_Qt {

RPP::Class
cLayout;

static VALUE
cBoxLayout_addLayout(VALUE v_self, VALUE v_layout)
{
  const RPP::QObject<QBoxLayout> self = v_self;
  const RPP::QObject<QLayout> layout = v_layout;
  self->addLayout(layout);
  return v_self;
}

R_QT_DEF_ALLOCATOR(HBoxLayout)
R_QT_DEF_ALLOCATOR(VBoxLayout)

static void
init_boxlayout(RPP::Module mQt, RPP::Class cLayout)
{
  const RPP::Class cBoxLayout = mQt.define_class("BoxLayout", cLayout);
  cBoxLayout.define_method("addLayout", cBoxLayout_addLayout);
  const RPP::Class cVBox = mQt.define_class("VBoxLayout", cBoxLayout);
  cVBox.define_alloc_func(cVBoxLayout_alloc);
  const RPP::Class cHBox = mQt.define_class("HBoxLayout", cBoxLayout);
  cHBox.define_alloc_func(cHBoxLayout_alloc);
}

R_QT_DEF_ALLOCATOR(GridLayout)

static VALUE
cGridLayout_columnCount_get(VALUE v_self)
{
  const RPP::QObject<QGridLayout> self = v_self;
  const RPP::Fixnum r = self.iv("@columnCount");
  return r.test() ? r : RPP::Fixnum(self->columnCount());
}

static VALUE
cGridLayout_columnCount_set(VALUE v_self, VALUE v_columnCount)
{
  const RPP::QObject<QGridLayout> self = v_self;
  const RPP::Fixnum r = self.iv("@columnCount");
  if (r.test()) rb_raise(rb_eNotImpError, "altering columnCount later on not supported yet");
  /* FIXME: this is symplistic.
   *
   * Later changes of columnCount are completely ignored since @columnCount is only 
   * used in setup...
   * We have to somehow re-add all widgets and layouts
   */
  self.iv_set("@columnCount", v_columnCount); 
  return v_columnCount;
}

#define GRIDLAYOUT_ADD(X) \
static VALUE \
cGridLayout_add##X(VALUE v_self, VALUE v_x) \
{ \
  const RPP::QObject<QGridLayout> self = v_self; \
  const RPP::QObject<Q##X> x = v_x; \
  int currow = RPP::Fixnum(self.iv("@currow")); \
  const int currow_org = currow; \
  int curcol = RPP::Fixnum(self.iv("@curcol")); \
  const int columnCount = RPP::Fixnum(self.call("columnCount")); \
  self->add##X(x, currow, curcol); \
  if (++curcol == columnCount) \
    { \
      currow++; \
      curcol = 0; \
    } \
  self.iv_set("@curcol", curcol); \
  if (currow_org != currow) \
    self.iv_set("@currow", currow); \
  x.iv_set("@parent", self); /* see cLayout_addWidget */ \
  return v_self; \
}

GRIDLAYOUT_ADD(Widget)
GRIDLAYOUT_ADD(Layout)

static void
init_gridlayout(RPP::Module mQt, RPP::Class cLayout)
{
  const RPP::Class cGridLayout = mQt.define_class("GridLayout", cLayout);
  cGridLayout.define_alloc_func(cGridLayout_alloc)
	     .define_method("columnCount_get", cGridLayout_columnCount_get)
	     .define_method("columnCount=", cGridLayout_columnCount_set)
	     .define_method("addWidget", cGridLayout_addWidget)
	     .define_method("addLayout", cGridLayout_addLayout)
	     ;
}

static VALUE
cLayout_addWidget(VALUE v_self, VALUE v_widget)
{
  const RPP::QObject<QLayout> self = v_self;
  const RPP::QObject<QWidget> widget = v_widget;
  self->addWidget(widget);
  // Qt reparents the widget to widget it is itself located in
  widget.iv_set("@parent", self);
  return self;
}

//override
static VALUE
cLayout_enqueue_children(int argc, VALUE *argv, VALUE v_self)
{
  VALUE v_queue;
  rb_scan_args(argc, argv, "01", &v_queue);
  trace1("cLayout_enqueue_children, yieldmode=%d", NIL_P(v_queue));
  const RPP::QObject<QLayout> self = v_self;
  const RPP::Object queue = v_queue;
  self.super(v_queue);
  const int N = self->count();
  trace2("%s::enqueue_childitems, N = %d", TO_CSTR(v_self), N);
  const bool yield = queue.isNil();
  for (int i = 0; i < N; i++)
    {
      QWidget * const w = self->itemAt(i)->widget();
      trace2("i=%d, w=%p", i, w);
      if (!w) continue; // ignore spacers
      const RPP::QObject<QWidget> child(w, RPP::UNSAFE);
      trace3("got class %s, name '%s', v_child=%s", QTCLASS(w), qString2cstr(w->objectName()), child.inspect());
      if (yield)
	{
	  if (child.test())
	    {
	      trace("YIELD widget");
	      child.yield();
	    }
	}
      else
	{
	  const RPP::Array q(queue);
	  if (child.isNil())
	    q.push(Data_Wrap_Struct(cSynthObject, 0, 0, w));
	  else
	    q.push(child);
	}
    }
  return Qnil;
} // cLayout_enqueue_children

void
init_layout(RPP::Module mQt, RPP::Class cControl)
{
  trace("init_layout");
  cLayout = mQt.define_class("Layout", cControl);
  cLayout.define_method("addWidget", cLayout_addWidget)
	 .define_method("enqueue_children", cLayout_enqueue_children);
  init_boxlayout(mQt, cLayout);
  init_gridlayout(mQt, cLayout);
}

} // namespace R_Qt
