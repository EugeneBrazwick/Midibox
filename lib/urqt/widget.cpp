
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
#include <QtGui/QResizeEvent>
#include "widget.h"
#include "size.h" // cSizeWrap	  
#include "layout.h" // cLayout
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
 *	resize int
 *	resize int, int
 */
static VALUE
cWidget_resize(int argc, VALUE *argv, VALUE v_self)
{
  const RPP::QObject<QWidget> self = v_self;
  self.check_frozen();
  //trace("cWidget_resize");
  self->resize(args2QSize(argc, argv));
  return v_self;
}

/** :call-seq:
 *
 *	size -> int, int
 */
static VALUE
cWidget_size_get(VALUE v_self)
{
  const RPP::QObject<QWidget> self = v_self;
  return cSizeWrap(self->size());
}

static VALUE
cWidget_minimumSize_set(int argc, VALUE *argv, VALUE v_self)
{
  const RPP::QObject<QWidget> self = v_self;
  self.check_frozen();
  trace("cWidget_resize");
  self->setMinimumSize(args2QSize(argc, argv));
  return Qnil;
}

static VALUE
cWidget_minimumSize_get(VALUE v_self)
{
  const RPP::QObject<QWidget> self = v_self;
  return cSizeWrap(self->minimumSize());
}

static VALUE
cWidget_maximumSize_set(int argc, VALUE *argv, VALUE v_self)
{
  const RPP::QObject<QWidget> self = v_self;
  self.check_frozen();
  trace("cWidget_resize");
  self->setMinimumSize(args2QSize(argc, argv));
  return Qnil;
}

static VALUE
cWidget_maximumSize_get(VALUE v_self)
{
  const RPP::QObject<QWidget> self = v_self;
  return cSizeWrap(self->maximumSize());
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

class EventSignalBroker: public QObject
{
private:
  typedef QObject inherited;
  // map event types to ruby callbacks
  QHash<QEvent::Type, const char *>Events;
protected:
  override bool eventFilter(QObject *object, QEvent *event);
public:
  EventSignalBroker(QObject *parent);
  void registerEvent(QEvent::Type tp, const char *method);
}; // class EventFilter

static const char 
ESB_PropertyId[] = R_QT_INTERNAL_PROPERTY_PREFIX "EventSignalBroker";

EventSignalBroker::EventSignalBroker(QObject *parent):
inherited(parent)
{
 //  parent->setProperty(ESB_PropertyId, this);
}

void 
EventSignalBroker::registerEvent(QEvent::Type tp, const char *method)
{
  if (Events.contains(tp)) return;
  // trace1("registerEvent %s", method);
  switch (tp)
    {
    case QEvent::Resize:
    case QEvent::Show:
      Events[tp] = method;
      if (Events[tp] != method) rb_raise(rb_eFatal, "QT IS BROKEN!!");
      return;
    default:
      break;
    }
  rb_raise(rb_eNotImpError, "events of type %s cannot be brokered yet", method);
}

/* 
 * Broker the event.
 * IE, for all registered events we must emit the signal.
 * But this only needs to be done if object has a ruby wrapper.
 *
 * Must return inherited::eventFilter in all cases
 */
bool 
EventSignalBroker::eventFilter(QObject *object, QEvent *event)
{
  const QEvent::Type tp = event->type();
  //trace1("eventFilter, received type '%d' <<<<<EVENT!!!!>>>>>", tp);
  const RPP::QObject<QObject> v_object(object, RPP::UNSAFE);
  if (v_object.test())
    {
      const char * const method = Events.value(tp);
      if (method)
	{
	  const RPP::Symbol v_method = method;
	  // if inspected or to_s then it works.
	  // Otherwise it calls emit with a Proc with address 0x00000000000
	  // using plain VALUE has the same result.
	  //track2("call %s::emit(%s)", v_object, v_method);
	  // unfortunately:
	  switch (tp)
	    {
	    case QEvent::Resize:
	      {
		const QResizeEvent &ev_resize = *static_cast<QResizeEvent *>(event);
		const QSize &sz = ev_resize.size();
		v_object.call("emit", v_method, RPP::Fixnum(sz.width()), 
			      RPP::Fixnum(sz.height()));
		break;
	      }
	    case QEvent::Show:
		trace1("calling rb_funcall(:emit), v_method = %p", &v_method);
		// using call or rb_funcall has SAME weird result
		v_object.call("emit", v_method);
		break;
	    default:
		rb_raise(rb_eNotImpError, "events of type %s cannot be brokered yet", method);
		break;
	    }
	}
    }
  else
    {
      trace1("Watched object %p is not a rb thing", object);
    }
  return inherited::eventFilter(object, event);
}

/** EVENT TRIGGERED SIGNAL
 * :call-seq:
 *    shown block
 *    shown *args
 */
static VALUE
cWidget_shown(int argc, VALUE *argv, VALUE v_self)
{
  // FIXME macro req.  EVENT_TRIGGERED_SIGNAL...
  const RPP::QObject<QWidget> self = v_self;
  EventSignalBroker *esb = 0;
  QVariant v = self->property(ESB_PropertyId);
  if (!v.isValid())
    {
      //trace("create the broker and cache it");
      esb = new EventSignalBroker(self);
      self->setProperty(ESB_PropertyId, QVariant(QMetaType::QObjectStar, esb));
      self->installEventFilter(esb); // Eugene assumes Qt does not own it.
    }
  else
      esb = static_cast<EventSignalBroker *>(v.value<QObject*>());
  const char *const method = "shown";
  esb->registerEvent(QEvent::Show, method);
  VALUE v_args, v_block;
  rb_scan_args(argc, argv, "*&", &v_args, &v_block);
  //track4("Object.signal_impl(%s, %s, %s, %s)", v_self, RPP::Symbol(method), v_args, v_block);
  cObject_signal_impl(v_self, method, v_args, v_block);
  return Qnil;
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
      return self.super(v_queue);
    }
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
	/*	QWidget.sizeHint is virtual but readonly...
	 *	And static properties do not merge with dynamic ones
	 *
	 *	The only solution is to subclass ALL widget subclasses with their own
	 *	sizeHint() crap.
	 .define_method("sizeHint=", cWidget_sizeHint_set), -1);
	 .define_method("sizeHint_get", cWidget_sizeHint_get), 0);
	 .funcall(rb_intern("attr_dynamic"), 2, cSize, CSTR2SYM("sizeHint"));
	*/
	 .define_method("title=", cWidget_title_set)
	 .define_method("title_get", cWidget_title_get)
	 .define_method("shown", cWidget_shown)
	 .define_method("layout", cWidget_layout)
	 .define_method("layout=", cWidget_layout_set)
	 .define_method("enqueue_children", cWidget_enqueue_children)
	 ;
  init_synthwidget(mQt, cWidget);
  return cWidget;
}

} // namespace R_Qt 
