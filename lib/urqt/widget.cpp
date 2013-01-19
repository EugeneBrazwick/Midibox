
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

// Comment the following out to remove the DEBUG tags:
#define TRACE

/** :rdoc:

widget.cpp

This file contains the QWidget wrapper.
*/
#pragma implementation
#include <QtCore/QQueue>
#include <QtWidgets/QWidget>
#include <QtWidgets/QLayout>
#include <QtGui/QResizeEvent>
#include <ruby.h>
#include "application.h"
#include "api_utils.h"
#include "object.h" // cObjectWrap

namespace R_Qt {

R_QT_DEF_ALLOCATOR(Widget)

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
  VALUE v_x, v_y;
  rb_scan_args(argc, argv, "02", &v_x, &v_y);
  const int x = NUM2INT(v_x);
  traqt1("%s::resize", QTCLASS(self));
  self->resize(x, NIL_P(v_y) ? x : NUM2INT(v_y));
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
  const QSize r = self->size();
  return rb_ary_new3(2, INT2NUM(r.width()), INT2NUM(r.height())); 
}

static VALUE cWidget;

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

static bool
locate_layout_child(QLayout *layout, QObject *child)
{
  const int N = layout->count();
  for (int i = 0; i < N; i++)
    {
      if (layout->itemAt(i)->widget() == child)
	return true;
    }
  return false;
}

static VALUE
cWidget_enqueue_children(VALUE v_self, VALUE v_queue)
{
  trace1("%s::each_child", TO_CSTR(v_self));
  RETURN_ENUMERATOR(v_self, 0, 0);
  // do not call super here
  RQTDECLSELF(QWidget);
  traqt1("%s::children", QTCLASS(self));
  const QObjectList &children = self->children();
  QLayout * const layout = self->layout(); // can be null
  if (!layout)
    return rb_call_super(1, &v_queue);
  const bool yield = !NIL_P(v_queue);
  if (!yield)
    v_queue = to_ary(v_queue);
  foreach (QObject *child, children)
    {
      /* We must not add widgets WITHIN a layout, since they are virtually
        parented to that layout.
	However that is not the same a widgets WITH a layout!
      */
      trace("check for isWidgetType and layout");
      if (layout && child->isWidgetType() && locate_layout_child(layout, child))
	continue;
      if (yield)
	{
	  const VALUE v_child = qt2v(child);
	  trace3("child=%s, isWidgetType=%d, layout=%p", INSPECT(v_child), child->isWidgetType(), child->isWidgetType() ? ((QWidget *)child)->layout() : (void *)0);
	  if (!NIL_P(v_child)) rb_yield(v_child);
	}
      else
	  rb_ary_push(v_queue, Data_Wrap_Struct(cObject, 0, 0, child));
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
  rb_define_method(cWidget, "title=", RUBY_METHOD_FUNC(cWidget_title_set), -1);
  rb_define_method(cWidget, "caption=", RUBY_METHOD_FUNC(cWidget_title_set), -1);
  rb_define_method(cWidget, "windowTitle=", RUBY_METHOD_FUNC(cWidget_title_set), -1);
  rb_define_method(cWidget, "title_get", RUBY_METHOD_FUNC(cWidget_title_get), 0);
  rb_define_method(cWidget, "caption_get", RUBY_METHOD_FUNC(cWidget_title_get), 0);
  rb_define_method(cWidget, "windowTitle_get", RUBY_METHOD_FUNC(cWidget_title_get), 0);
  rb_define_method(cWidget, "shown", RUBY_METHOD_FUNC(cWidget_shown), -1);
  rb_define_method(cWidget, "layout", RUBY_METHOD_FUNC(cWidget_layout), 0);
  rb_define_method(cWidget, "layout=", RUBY_METHOD_FUNC(cWidget_layout_set), 1);
  rb_define_method(cWidget, "enqueue_children", RUBY_METHOD_FUNC(cWidget_enqueue_children), 1);
  return cWidget;
}

} // namespace R_Qt 
