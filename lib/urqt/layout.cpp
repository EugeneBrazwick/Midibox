
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
#include "urqtCore/qtflags_and_enums.h"
#include "ruby++/array.h"
#include "ruby++/hash.h"

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
  /* FIXME: this is symplistic.
   *
   * Later changes of columnCount are completely ignored since @columnCount is only 
   * used in setup...
   * We have to somehow re-add all widgets and layouts
   */
  if (r.test()) rb_raise(rb_eNotImpError, "altering columnCount later on not supported yet");
  self.iv_set("@columnCount", v_columnCount); 
  return v_columnCount;
}

/* Notice that 'setup' will actually re-add them!!
 *
 * addWidget	widget
 * addWidget    widget, row, col [, alignment]
 * addWidget    widget, row, col, rowspan, colspan [, alignment]
 */
static VALUE
cGridLayout_addWidget(int argc, VALUE *argv, VALUE v_self)
{
  const RPP::QObject<QGridLayout> self = v_self;
  trace2("%s::addWidget, argc=%d", self.inspect(), argc);
  RPP::QObject<QWidget> item(RPP::UNSAFE);
  RPP::Fixnum row, col, rowspan, colspan;
  RPP::Array alsyms(RPP::UNSAFE);
  trace("scanning");
  RPP::Scan scan(argc, argv);
  scan.arg(item);
  track1("adding %s", item);
  scan.opts(row, col);	   // it is called 'illegally' somewhere
  track2("row=%s, col=%s", row, col);
  scan.opts(rowspan, colspan, alsyms);
  if (row.isNil()) row = 1;
  if (col.isNil()) col = 1;
  track2("rowspan=%s, colspan=%s", rowspan, colspan);
  if (rowspan.isArray()) // oops, must be alignment then
    {
      alsyms.assign(rowspan);
      rowspan = Qnil;
    }
  const Qt::Alignment alignment = alsyms2qtalignment(alsyms);
  if (rowspan.isNil())
      self->addWidget(item, row, col, alignment);
  else
    {
      track4("calling addWidget(%s, %s, %s, %s)", row, col, rowspan, colspan);
      self->addWidget(item, row, col, rowspan, colspan, alignment);
    }
  item.iv_set("@parent", self);
  return v_self;
}

static VALUE
cGridLayout_addLayout(int argc, VALUE *argv, VALUE v_self)
{
  const RPP::QObject<QGridLayout> self = v_self;
  RPP::QObject<QLayout> item(RPP::UNSAFE);
  RPP::Fixnum row, col, rowspan, colspan;
  RPP::Array alsyms(RPP::UNSAFE);
  RPP::Scan(argc, argv).arg(item)
		       .opts(row, col)
		       .opts(rowspan, colspan, alsyms);
  if (row.isNil()) row = 1;
  if (col.isNil()) col = 1;
  if (rowspan.isArray()) // oops, must be alignment then
    {
      alsyms.assign(rowspan);
      rowspan = Qnil;
    }
  const Qt::Alignment alignment = alsyms2qtalignment(alsyms);
  if (rowspan.isNil())
    self->addLayout(item, row, col, alignment);
  else
    self->addLayout(item, row, col, rowspan, colspan, alignment);
  item.iv_set("@parent", self);
  return v_self;
}

/* TOO EARLY...
 *
 * controls are added to parents first, and then we call setup.
#define GRIDLAYOUT_ADD(X) \
static VALUE \
cGridLayout_add##X(VALUE v_self, VALUE v_x) \
{ \
  const RPP::QObject<QGridLayout> self = v_self; \
  const RPP::QObject<Q##X> x = v_x; \
  int currow = RPP::Fixnum(self.iv("@currow")); \
  const int currow_org = currow; \
  int curcol = RPP::Fixnum(self.iv("@curcol")); \
  const int curcol_org = curcol; \
  const int columnCount = RPP::Fixnum(self.call("columnCount")); \
  const RPP::Array span = self.call("span"); \
  track1("Applying span %s", span); \
  const RPP::Object objspanc = span[0]; \
  const int spanc = objspanc.isSymbol() \
		    && RPP::Symbol(objspanc) == "all_remaining" ? (columnCount - curcol > 1 ? columnCount - curcol : 1) \
								: objspanc.to_i(); \
  const int spanr = RPP::Fixnum(span[1]); \
  self->add##X(x, currow, curcol, spanr, spanc); \
  curcol += spanc; \
  if (curcol >= columnCount) \
    { \
      currow++; \
      curcol = 0; \
    } \
  if (curcol_org != curcol) self.iv_set("@curcol", curcol); \
  if (currow_org != currow) self.iv_set("@currow", currow); \
  x.iv_set("@parent", self); // see cLayout_addWidget 
  return v_self; \
}

GRIDLAYOUT_ADD(Widget)
GRIDLAYOUT_ADD(Layout)
*/

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

#define QTSIZECONSTRAINTS \
      QTSIZECONSTRAINT_DO(default, DefaultConstraint) \
      QTSIZECONSTRAINT_DO(fixedSize, FixedSize) \
      QTSIZECONSTRAINT_DO(minimumSize, MinimumSize) \
      QTSIZECONSTRAINT_DO(maximumSize, MaximumSize) \
      QTSIZECONSTRAINT_DO(minAndMaxSize, MinAndMaxSize) \
      QTSIZECONSTRAINT_DO(noConstraint, NoConstraint) \

static VALUE
cLayout_sizeConstraint_set(VALUE v_self, VALUE v_szconstraint)
{
  const RPP::QObject<QLayout> self = v_self;
  self.check_frozen();
  RPP::Dictionary syms(cLayout.cv("@@sizeConstraints"), RPP::VERYUNSAFE);
  if (!syms.isHash())
    {
      syms = RPP::Dictionary();
      cLayout.cv_set("@@sizeConstraints", syms);
#define QTSIZECONSTRAINT_DO(sym, qtor) \
      syms[#sym] = int(QLayout::Set##qtor);
      QTSIZECONSTRAINTS
      QTSIZECONSTRAINT_DO(none, NoConstraint)
#undef QTSIZECONSTRAINT_DO
    }
  const RPP::Fixnum szconstraint = syms[v_szconstraint];
  self->setSizeConstraint(QLayout::SizeConstraint(szconstraint.to_i()));
  return v_szconstraint;
}

static VALUE
cLayout_sizeConstraint_get(VALUE v_self)
{
  const RPP::QObject<QLayout> self = v_self;
  switch (self->sizeConstraint())
    {
#define QTSIZECONSTRAINT_DO(sym, qtor) \
      case QLayout::Set##qtor: return RPP::Symbol(#sym);
      QTSIZECONSTRAINTS
    }
  rb_raise(rb_eRuntimeError, "Unhandled sizeconstraint %d", self->sizeConstraint());
}

void
init_layout(RPP::Module mQt, RPP::Class cControl)
{
  trace("init_layout");
  cLayout = mQt.define_class("Layout", cControl);
  cLayout.define_method("addWidget", cLayout_addWidget)
	 .define_method("enqueue_children", cLayout_enqueue_children)
	 .define_method("sizeConstraint_get", cLayout_sizeConstraint_get)
	 .define_method("sizeConstraint=", cLayout_sizeConstraint_set)
	 ;
  init_boxlayout(mQt, cLayout);
  init_gridlayout(mQt, cLayout);
}

} // namespace R_Qt
