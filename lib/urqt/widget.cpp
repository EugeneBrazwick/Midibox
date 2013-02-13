
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
#include "object.h" // cObjectWrap

namespace R_Qt {

R_QT_DEF_ALLOCATOR(Widget)

static VALUE
cSynthWidget = Qnil;

static VALUE
cWidget_show(VALUE v_self)
{
  trace("cWidget_show");
  RQTDECLSELF(QWidget);
  traqt1("%s::show", QTCLASS(self));
  self->show();
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
  rb_check_frozen(v_self);
  RQTDECLSELF(QWidget);
  trace("cWidget_resize");
  traqt1("%s::resize", QTCLASS(self));
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
  RQTDECLSELF(QWidget);
  traqt1("%s::size", QTCLASS(self));
  return cSizeWrap(self->size());
}

static VALUE
cWidget_minimumSize_set(int argc, VALUE *argv, VALUE v_self)
{
  rb_check_frozen(v_self);
  RQTDECLSELF(QWidget);
  trace("cWidget_resize");
  self->setMinimumSize(args2QSize(argc, argv));
  return Qnil;
}

static VALUE
cWidget_minimumSize_get(VALUE v_self)
{
  RQTDECLSELF(QWidget);
  return cSizeWrap(self->minimumSize());
}

static VALUE
cWidget_maximumSize_set(int argc, VALUE *argv, VALUE v_self)
{
  rb_check_frozen(v_self);
  RQTDECLSELF(QWidget);
  trace("cWidget_resize");
  self->setMinimumSize(args2QSize(argc, argv));
  return Qnil;
}

static VALUE
cWidget_maximumSize_get(VALUE v_self)
{
  RQTDECLSELF(QWidget);
  return cSizeWrap(self->maximumSize());
}

VALUE 
cWidget = Qnil;

static VALUE 
cWidget_qtparent_set(VALUE v_self, VALUE v_parent)
{
  track2("cObject_parent_set(%s, %s)", v_self, v_parent);
  rb_check_frozen(v_self);
  QWidget *parent = 0;
  if (!NIL_P(v_parent))
    {
      const VALUE v_p = v_parent;
      RQTDECLARE(QWidget, p);
      parent = p;
    }
  RQTDECLSELF(QWidget);
  trace("Calling setParent");
  traqt2("%s::setParent(%s)", QTCLASS(self), QTCLASS(parent));
  self->setParent(parent);
  return v_parent;
}

static VALUE
cWidget_title_get(VALUE v_self)
{
  RQTDECLSELF(QWidget);
  traqt1("%s::windowTitle", QTCLASS(self));
  return qString2v(self->windowTitle());
} // Widget#title

static VALUE
cWidget_title_set(int argc, VALUE *argv, VALUE v_self)
{
  RQTDECLSELF(QWidget);
  rb_check_frozen(v_self);
  VALUE v_title;
  rb_scan_args(argc, argv, "1", &v_title);
  traqt2("%s::setWindowTitle(%s)", QTCLASS(self), TO_S(v_title));
  self->setWindowTitle(StringValueCStr(v_title));
  return v_self;
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
  trace1("registerEvent %s", method);
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
  traqt("QEvent::type");
  const QEvent::Type tp = event->type();
  trace1("eventFilter, received type '%d' <<<<<EVENT!!!!>>>>>", tp);
  const VALUE v_object = qt2v(object);
  if (!NIL_P(v_object))
    {
      const char * const method = Events.value(tp);
      if (method)
	{
	  trace1("emit %s()", method);
	  const VALUE v_method = CSTR2SYM(method);
	  // unfortunately:
	  switch (tp)
	    {
	    case QEvent::Resize:
	      {
		const QResizeEvent &ev_resize = *static_cast<QResizeEvent *>(event);
		traqt("QResizeEvent::size");
		const QSize &sz = ev_resize.size();
		rb_funcall(v_object, rb_intern("emit"), 3, v_method,
			   INT2NUM(sz.width()), INT2NUM(sz.height()));
		break;
	      }
	    case QEvent::Show:
		track2("%s::emit(%s)", v_object, v_method);
		rb_funcall(v_object, rb_intern("emit"), 1, v_method);
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
  trace1("cWidget_shown, argc=%d", argc);
  // FIXME macro req.  EVENT_TRIGGERED_SIGNAL...
  RQTDECLSELF(QWidget);
  EventSignalBroker *esb = 0;
  traqt2("%s::property(%s)", QTCLASS(self), ESB_PropertyId);
  QVariant v = self->property(ESB_PropertyId);
  traqt("QVariant::isValid");
  if (!v.isValid())
    {
      trace("create the broker and cache it");
      esb = new EventSignalBroker(self);
      // WTF QVariant cannot store QObject* ????
      traqt1("%s::setProperty", QTCLASS(self));
      self->setProperty(ESB_PropertyId, QVariant(QMetaType::QObjectStar, esb));
      traqt2("%s::installEventFilter(%s)", QTCLASS(self), QTCLASS(esb));
      self->installEventFilter(esb); // Eugene assumes Qt does not own it.
    }
  else
    {
      traqt("QVariant::value<QObject>");
      esb = static_cast<EventSignalBroker *>(v.value<QObject*>());
    }
  const char *const method = "shown";
  esb->registerEvent(QEvent::Show, method);
  VALUE v_args, v_block;
  rb_scan_args(argc, argv, "*&", &v_args, &v_block);
  cObject_signal_impl(v_self, method, v_args, v_block);
  return Qnil;
} // Widget#shown

static VALUE
cWidget_enqueue_children(VALUE v_self, VALUE v_queue)
{
  const bool yield = NIL_P(v_queue);
  trace2("%s::enqueue_children, yieldmode=%d", TO_CSTR(v_self), yield);
  // do not call super here
  RQTDECLSELF(QWidget);
  QLayout * const layout = self->layout(); // can be null
  if (!layout)
    {
      trace("no layout, revert to cObject_enqueue_children");
      return rb_call_super(1, &v_queue);
    }
  traqt1("%s::children", QTCLASS(self));
  const QObjectList &children = self->children();
  trace1("#children = %d", children.count());
  foreach (QObject *child, children)
    {
      /* We must not add widgets WITHIN a layout, since they are virtually
        parented to that layout.
	However that is not the same as widgets WITH a layout!


COMPLICATION: widgets may be nested multiple times:
	      widget1 { vbox { hbox { vbox { widget2 }}}}
    widget2 now has qtparent widget1

      */
      trace("check for isWidgetType and layout");
      const VALUE v_child = qt2v(child);
      if (layout && child->isWidgetType())
	{
	  if (!NIL_P(v_child)) 
	    {
	      const VALUE v_parent = rb_funcall(v_child, rb_intern("parent"), 0);
	      if (rb_obj_is_kind_of(v_parent, cLayout))
		{
		  track1("located child %s in layout: SKIP!!", v_child);
		  continue;
		}
	    }
	}
      if (yield)
	{
	  if (!NIL_P(v_child)) 
	    {
	      track1("YIELD child=%s", v_child);
	      rb_yield(v_child);
	    }
	}
      else
	{
	  trace("add child to v_queue");
	  Check_Type(v_queue, T_ARRAY);
	  if (NIL_P(v_child)) 
	    rb_ary_push(v_queue, 
		        Data_Wrap_Struct(child->isWidgetType() ? cSynthWidget : cSynthObject, 
					 0, 0, child));
	  else
	    rb_ary_push(v_queue, v_child);
	}
    }
  return Qnil;
} // cWidget_enqueue_children

static VALUE
cWidget_layout(VALUE v_self)
{
  RQTDECLSELF(QWidget);
  QLayout * const layout = self->layout();
  return layout ? qt2v(layout) : Qnil;
}

static VALUE
cWidget_layout_set(VALUE v_self, VALUE v_layout)
{
  RQTDECLSELF(QWidget);
  RQTDECLARE(QLayout, layout);
  self->setLayout(layout);
  return v_self;
} 

/*
static VALUE
cWidget_sizeHint_set(int argc, VALUE *argv, VALUE v_self)
{
  RQTDECLSELF(QWidget);
  const QSizeF sz = args2QSizeF(argc, argv);
  // FAILS:  sizeHint() is READONLY!!!!
  self->setProperty("sizeHint", sz);
  // DOES THIS WORK??? ie ,  will self->sizeHint now return the size??
  if (self->sizeHint() != sz) rb_fatal("Er.....");
  return Qnil;
}

static VALUE
cWidget_sizeHint_get(VALUE v_self)
{
  RQTDECLSELF(QWidget);
  return cSizeWrap(self->sizeHint());
}
*/

static VALUE
cSynthWidget_synththesized_p(VALUE)
{
  return Qtrue;
}

static inline void
init_synthwidget(VALUE mQt, VALUE cWidget)
{
  cSynthWidget = rb_define_class_under(mQt, "SynthWidget", cWidget);
  rb_define_method(cSynthWidget, "synthesized?", RUBY_METHOD_FUNC(cSynthWidget_synththesized_p), 0);
}

VALUE
init_widget(VALUE mQt, VALUE cControl)
{
  trace1("init_widget, define R::Qt::Widget, mQt=%p", (void *)mQt);
  cWidget = rb_define_class_under(mQt, "Widget", cControl);
  rb_define_alloc_func(cWidget, cWidget_alloc);
  rb_define_method(cWidget, "show", RUBY_METHOD_FUNC(cWidget_show), 0);
  rb_define_method(cWidget, "qtparent=", RUBY_METHOD_FUNC(cWidget_qtparent_set), 1);
  rb_define_method(cWidget, "resize", RUBY_METHOD_FUNC(cWidget_resize), -1);
  rb_define_method(cWidget, "size=", RUBY_METHOD_FUNC(cWidget_resize), -1);
  rb_define_method(cWidget, "size_get", RUBY_METHOD_FUNC(cWidget_size_get), 0);
  rb_define_method(cWidget, "minimumSize=", RUBY_METHOD_FUNC(cWidget_minimumSize_set), -1);
  rb_define_method(cWidget, "minimumSize_get", RUBY_METHOD_FUNC(cWidget_minimumSize_get), 0);
  rb_funcall(cWidget, rb_intern("attr_dynamic"), 2, cSize, CSTR2SYM("minimumSize"));
  rb_define_method(cWidget, "maximumSize=", RUBY_METHOD_FUNC(cWidget_maximumSize_set), -1);
  rb_define_method(cWidget, "maximumSize_get", RUBY_METHOD_FUNC(cWidget_maximumSize_get), 0);
  rb_funcall(cWidget, rb_intern("attr_dynamic"), 2, cSize, CSTR2SYM("maximumSize"));
  /*	QWidget.sizeHint is virtual but readonly...
   *	And static properties do not merge with dynamic ones
   *
   *	The only solution is to subclass ALL widget subclasses with their own
   *	sizeHint() crap.
  rb_define_method(cWidget, "sizeHint=", RUBY_METHOD_FUNC(cWidget_sizeHint_set), -1);
  rb_define_method(cWidget, "sizeHint_get", RUBY_METHOD_FUNC(cWidget_sizeHint_get), 0);
  rb_funcall(cWidget, rb_intern("attr_dynamic"), 2, cSize, CSTR2SYM("sizeHint"));
  */
  rb_define_method(cWidget, "title=", RUBY_METHOD_FUNC(cWidget_title_set), -1);
  rb_define_method(cWidget, "caption=", RUBY_METHOD_FUNC(cWidget_title_set), -1);
  rb_define_method(cWidget, "windowTitle=", RUBY_METHOD_FUNC(cWidget_title_set), -1);
  rb_define_method(cWidget, "title_get", RUBY_METHOD_FUNC(cWidget_title_get), 0);
  rb_define_method(cWidget, "caption_get", RUBY_METHOD_FUNC(cWidget_title_get), 0);
  rb_define_method(cWidget, "windowTitle_get", RUBY_METHOD_FUNC(cWidget_title_get), 0);
  rb_define_method(cWidget, "shown", RUBY_METHOD_FUNC(cWidget_shown), -1);
  rb_define_method(cWidget, "layout", RUBY_METHOD_FUNC(cWidget_layout), 0);
  rb_define_method(cWidget, "layout=", RUBY_METHOD_FUNC(cWidget_layout_set), 1);
  rb_define_protected_method(cWidget, "enqueue_children", 
			     RUBY_METHOD_FUNC(cWidget_enqueue_children), 1);
  init_synthwidget(mQt, cWidget);
  return cWidget;
}

} // namespace R_Qt 
