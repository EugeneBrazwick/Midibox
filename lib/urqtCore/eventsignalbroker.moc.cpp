
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

//#define TRACE

#pragma implementation
#include "eventsignalbroker.moc.h"
#include "ruby++/symbol.h"

namespace R_Qt {

const char 
ObjectEventBroker::ESB_PropertyId[] = R_QT_INTERNAL_PROPERTY_PREFIX "ObjectEventBroker";

ObjectEventBroker::ObjectEventBroker(QObject *parent):
inherited(parent)
{
  trace("new ObjectEventBroker");
} // ObjectEventBroker

void 
ObjectEventBroker::registerEvent(QEvent::Type tp, const char *method)
{
  if (Events.contains(tp)) return;
  trace2("registerEvent :%s for tp %d", method, tp);
  Events[tp] = method;
} // registerEvent

void 
ObjectEventBroker::event_filter(const RPP::QObject<QObject> object,
				const QEvent &event,
				RPP::Symbol method) const
{
  trace1("event_filter, tp = %d", event.type());
  switch (event.type())
    {
    case QEvent::Timer:
      {
	const QTimerEvent &ev_timer = static_cast<const QTimerEvent &>(event);
	object.call("emit", method, RPP::Fixnum(ev_timer.timerId()));
	return;
      }
    case QEvent::ChildAdded:
    case QEvent::ChildRemoved:
    case QEvent::ChildPolished:
      {
	const QChildEvent &ev_child = static_cast<const QChildEvent &>(event);
	object.call("emit", method, RPP::QObject<QObject>(ev_child.child()));
	return;
      }
    case QEvent::DynamicPropertyChange:
      {
	const QDynamicPropertyChangeEvent &ev_dpch 
	  = static_cast<const QDynamicPropertyChangeEvent &>(event);
	object.call("emit", method, qByteArray2v(ev_dpch.propertyName()));
	return;
      }
    default:
	break;
    }
  rb_raise(rb_eNotImpError, "events of type %s cannot be brokered yet", method.to_s());
}

/* 
 * Broker the event.
 * IE, for all registered events we must emit the signal.
 * But this only needs to be done if object has a ruby wrapper.
 *
 * Must return inherited::eventFilter in all cases
 */
bool 
ObjectEventBroker::eventFilter(QObject *object, QEvent *event)
{
  const QEvent::Type tp = event->type();
  trace1("eventFilter, received type '%d' <<<<<EVENT!!!!>>>>>", tp);
  const RPP::QObject<QObject> v_object(object, RPP::UNSAFE);
  if (v_object.test())
    {
      const char * const method = Events.value(tp);
      if (method)
	{
	  const RPP::Symbol v_method = method;
	  event_filter(v_object, *event, v_method);
	}
    }
  else
    {
      trace1("Watched object %p is not a rb thing", object);
    }
  return inherited::eventFilter(object, event);
} // eventFilter

VALUE 
ObjectEventBroker::signal(QEvent::Type tp, const char *method, int argc, VALUE *argv, VALUE v_self)
{
  trace4("signal(tp:%d, :%s, argc:%d, on: %s)", tp, method, argc, INSPECT(v_self));
  ObjectEventBroker *esb = 0;
  const RPP::QObject<QObject> self = v_self;
  QVariant v = self->property(ESB_PropertyId);
  if (!v.isValid())
    {
      //trace("create the broker and cache it");
      esb = new ObjectEventBroker(self);
      //trace2("created broker %p on QObject %p", esb, &self);
      v = QVariant(QMetaType::QObjectStar, &esb); // beware the '&'!!
      //QObject * const ptr = v.value<QObject*>(); // qvariant_cast<QObject*>(v); // v.value<QObject*>();
      //trace2("reversed ptr lookup -> %p, should be %p", ptr, esb); // SEGV
      self->setProperty(ESB_PropertyId, v);
      trace("calling installEventFilter");
      self->installEventFilter(esb); // Eugene assumes Qt does not own it.
    }
  else
    {
      //trace1("cast existing broker, loaded from QObject %p", &self);
      QObject * const ptr = v.value<QObject*>();
      //trace1("cast existing broker %p", ptr);
      esb = static_cast<ObjectEventBroker *>(ptr);
      //trace1("cast existing broker -> %p", esb);
    }
  //trace("Calling registerEvent()");
  esb->registerEvent(tp, method);
  VALUE v_args, v_block;
  rb_scan_args(argc, argv, "*&", &v_args, &v_block);
  track4("Object.signal_impl(%s, %s, %s, %s)", v_self, RPP::Symbol(method), v_args, v_block);
  /* cObject_signal_impl connects or emits a Ruby native signal.
   * Does not use Qt's signals or slots
   */
  cObject_signal_impl(v_self, method, v_args, v_block);
  return Qnil;
}

} // namespace R_Qt 
