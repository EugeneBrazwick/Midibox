
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

// Comment the following out to remove the DEBUG tags:
//#define TRACE

/** :rdoc:

widget.cpp

This file contains the QWidget wrapper.
*/
#pragma implementation
#include <QtCore/QQueue>
#include <QtWidgets/QWidget>
#include <QtWidgets/QLayout>
#include "widget.h"
#include "font.h"
#include "size.h" // cSizeWrap	  
#include "layout.h" // cLayout
#include "guieventsignalbroker.moc.h"
#include "urqtCore/margins.h"
#include "ruby++/rppstring.h"
#include "ruby++/array.h"

namespace R_Qt {

static VALUE
cWidget_alloc(VALUE cWidget)
{
  return RPP::QObject<QWidget>(cWidget, new QWidget);
}

static RPP::Class
cSynthWidget;

static VALUE
cWidget_show(VALUE v_self)
{
  RPP::QObject<QWidget>(v_self)->show();
  return v_self;
}

/** :call-seq:
 *
 *	resize QSize
 */
static VALUE
cWidget_resize(int argc, VALUE *argv, VALUE v_self)
{
  const RPP::QObject<QWidget> self = v_self;
  self.check_frozen();
  trace1("cWidget_resize, argc=%d", argc);
  const QSize sz = RPP::QSize(argc, argv);
  trace2("Calling QWidget::resize(%d, %d)", sz.width(), sz.height());
  self->resize(sz);
  return v_self;
}

/** :call-seq:
 *
 *	size -> int, int
 */
static VALUE
cWidget_size_get(VALUE v_self)
{
  return RPP::QSize(RPP::QObject<QWidget>(v_self)->size());
}

static VALUE
cWidget_minimumSize_set(int argc, VALUE *argv, VALUE v_self)
{
  const RPP::QObject<QWidget> self = v_self;
  self.check_frozen();
  self->setMinimumSize(RPP::QSize(argc, argv));
  return Qnil;
}

static VALUE
cWidget_minimumSize_get(VALUE v_self)
{
  return RPP::QSize(RPP::QObject<QWidget>(v_self)->minimumSize());
}

static VALUE
cWidget_maximumSize_set(int argc, VALUE *argv, VALUE v_self)
{
  const RPP::QObject<QWidget> self = v_self;
  self.check_frozen();
  self->setMaximumSize(RPP::QSize(argc, argv));
  return Qnil;
}

static VALUE
cWidget_maximumSize_get(VALUE v_self)
{
  return RPP::QSize(RPP::QObject<QWidget>(v_self)->maximumSize());
}

RPP::Class 
cWidget;

static VALUE 
cWidget_qtparent_set(VALUE v_self, VALUE v_parent)
{
  track2("cObject_parent_set(%s, %s)", v_self, v_parent);
  const RPP::QObject<QWidget> self = v_self;
  self.check_frozen();
  const RPP::QObject<QWidget> parent(v_parent, RPP::UNSAFE);
  trace("Calling setParent");
  self->setParent(parent);
  return parent;
}

static VALUE
cWidget_title_get(VALUE v_self)
{
  const RPP::QObject<QWidget> self = v_self;
  return qString2v(self->windowTitle());
} // Widget#title

static VALUE
cWidget_title_set(VALUE v_self, VALUE v_title)
{
  const RPP::QObject<QWidget> self = v_self;
  self.check_frozen();
  self->setWindowTitle(RPP::String(v_title).to_s());
  return v_title;
} // Widget#title

/** EVENT TRIGGERED SIGNAL
 * :call-seq:
 *    shown block
 *    shown *args
 */
static VALUE
cWidget_shown(int argc, VALUE *argv, VALUE v_self)
{
  return WidgetEventBroker::signal(QEvent::Show, "shown", argc, argv, v_self); 
} // Widget#shown

static VALUE
cWidget_enqueue_children(int argc, VALUE *argv, VALUE v_self)
{
  const RPP::QObject<QWidget> self = v_self;
  VALUE v_queue;
  rb_scan_args(argc, argv, "01", &v_queue);
  const bool yield = NIL_P(v_queue);
  //trace2("%s::enqueue_children, yieldmode=%d", TO_CSTR(v_self), yield);
  QLayout * const layout = self->layout(); // can be null
  if (!layout)
    {
      //trace("no layout, revert to cObject_enqueue_children");
      self.super(v_queue);
    }
  else
    {
      const QObjectList &children = self->children();
      //trace1("#children = %d", children.count());
      foreach (QObject *child, children)
	{
	  /* We must not add widgets WITHIN a layout, since they are virtually
	    parented to that layout.
	    However that is not the same as widgets WITH a layout!


    COMPLICATION: widgets may be nested multiple times:
		  widget1 { vbox { hbox { vbox { widget2 }}}}
	widget2 now has qtparent widget1

	  */
	  //trace("check for isWidgetType and layout");
	  const RPP::Object v_child = qt2v(child);
	  if (layout && child->isWidgetType())
	    {
	      if (!v_child.isNil())
		{
		  const RPP::Object parent = v_child.call("parent");
		  if (parent.is_kind_of(cLayout))
		    {
		      //track1("located child %s in layout: SKIP!!", v_child);
		      continue;
		    }
		}
	    }
	  if (yield)
	    {
	      if (!v_child.isNil())
		{
		  //track1("YIELD child=%s", v_child);
		  v_child.yield();
		}
	    }
	  else
	    {
	      trace("add child to v_queue");
	      const RPP::Array queue = v_queue;
	      if (v_child.isNil())
		queue.push(Data_Wrap_Struct(child->isWidgetType() ? cSynthWidget : cSynthObject, 
					    0, 0, child));
	      else
		queue.push(v_child);
	    }
	}
    }
  const RPP::Object font = self.iv("@font");
  if (!font.isNil())
    {
      if (yield)
	font.yield();
      else
	RPP::Array(v_queue).push(font);
    }
  return Qnil;
} // cWidget_enqueue_children

static VALUE
cWidget_layout(VALUE v_self)
{
  const RPP::QObject<QWidget> self = v_self;
  QLayout * const layout = self->layout();
  return layout ? qt2v(layout) : Qnil;
}

static VALUE
cWidget_layout_set(VALUE v_self, VALUE v_layout)
{
  const RPP::QObject<QWidget> self = v_self;
  const RPP::QObject<QLayout> layout = v_layout;
  self->setLayout(layout);
  return v_self;
} 

static inline void
init_synthwidget(RPP::Module mQt, RPP::Class cWidget)
{
  cSynthWidget = mQt.define_class("SynthWidget", cWidget);
}

static VALUE
cWidget_contentsMargins_get(VALUE v_self)
{
  return RPP::QMargins(RPP::QObject<QWidget>(v_self)->contentsMargins());
}

static VALUE
cWidget_contentsMargins_set(int argc, VALUE *argv, VALUE v_self)
{
  trace("contentsMargins_set");
  const RPP::QObject<QWidget> self = v_self;
  self.check_frozen();
  trace("calling QMargins argc/argv constructor");
  const RPP::QMargins m(argc, argv);
  track1("setContentsMargins(%s)", m);
  self->setContentsMargins(m);
  return Qnil;
}

/* FIXME:   
 *    pen+brush are considered children.
 *    I set @parent in cWidget_font_get in the font, so it 
 *    is assumed that font objects are not shared to begin with.
 *    This is all rather fuzzy.
 *
 */
static VALUE
cWidget_font_set(VALUE v_self, VALUE v_font)
{
  const RPP::QObject<QWidget> self = v_self;
  const RPP::QFont font(v_font, RPP::UNSAFE);
  self.iv_set("@font", font);
  if (font.isNil())
    self->setFont(QFont()); // default, I hope
  else
    self->setFont(font);
  return v_font;
}

static VALUE
cWidget_font_get(VALUE v_self)
{
  track2("%s::font_get, @font=%s", v_self, rb_iv_get(v_self, "@font"));
  const RPP::QObject<QWidget> self = v_self;
  RPP::QFont font(self.iv("@font"), RPP::UNSAFE);
  if (font.isNil()) 
    {
      font = self->font();
      font.iv_set("@parent", v_self);
      self.iv_set("@font", font);
    }
  return font;
}

VALUE
init_widget(RPP::Module mQt, RPP::Class cControl)
{
  //trace1("init_widget, define R::Qt::Widget, mQt=%p", &mQt);
  cWidget = mQt.define_class("Widget", cControl);
  cWidget.define_alloc_func(cWidget_alloc)
	 .define_method("show", cWidget_show)
	 .define_method("qtparent=", cWidget_qtparent_set)
	 .define_method("resize", cWidget_resize)
	 .define_method("size=", cWidget_resize)
	 .define_method("size_get", cWidget_size_get)
	 .define_method("minimumSize=", cWidget_minimumSize_set)
	 .define_method("minimumSize_get", cWidget_minimumSize_get)
	 .define_method("maximumSize=", cWidget_maximumSize_set)
	 .define_method("maximumSize_get", cWidget_maximumSize_get)
	 .define_method("contentsMargins=", cWidget_contentsMargins_set)
	 .define_method("contentsMargins_get", cWidget_contentsMargins_get)
	 .define_method("title=", cWidget_title_set)
	 .define_method("title_get", cWidget_title_get)
	 .define_method("shown", cWidget_shown)
	 .define_method("layout", cWidget_layout)
	 .define_method("layout=", cWidget_layout_set)
	 .define_method("enqueue_children", cWidget_enqueue_children)
	 .define_method("font_get", cWidget_font_get)
	 .define_method("font=", cWidget_font_set)
	 ;
  init_synthwidget(mQt, cWidget);
  return cWidget;
}

} // namespace R_Qt 
