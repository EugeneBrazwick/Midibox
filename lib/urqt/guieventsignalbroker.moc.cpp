
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

#pragma implementation
#include "guieventsignalbroker.moc.h"
#include "urqtCore/size.h"
#include <QtGui/QResizeEvent>

namespace R_Qt {

void 
WidgetEventBroker::event_filter(const RPP::QObject<QObject> object,
				   const QEvent &event,
				   RPP::Symbol method) const
{
  switch (event.type())
    {
    case QEvent::Resize:
      {
	const QResizeEvent &ev_resize = static_cast<const QResizeEvent &>(event);
	object.call("emit", method, RPP::QSize(ev_resize.size()));
	return;
      }
    case QEvent::Show:
	object.call("emit", method);
	return;
    default:
	break;
    }
  inherited::event_filter(object, event, method);
} // event_filter

VALUE 
WidgetEventBroker::signal(QEvent::Type tp, const char *method, 
		          int argc, VALUE *argv, VALUE v_self)
{
  WidgetEventBroker *esb = 0;
  const RPP::QObject<QObject> self = v_self;
  QVariant v = self->property(ESB_PropertyId);
  if (!v.isValid())
    {
      //trace("create the broker and cache it");
      esb = new WidgetEventBroker(self);
      self->setProperty(ESB_PropertyId, QVariant(QMetaType::QObjectStar, &esb));
      self->installEventFilter(esb); // Eugene assumes Qt does not own it.
    }
  else
      esb = static_cast<WidgetEventBroker *>(v.value<QObject*>());
  esb->registerEvent(tp, method);
  VALUE v_args, v_block;
  rb_scan_args(argc, argv, "*&", &v_args, &v_block);
  //track4("Object.signal_impl(%s, %s, %s, %s)", v_self, RPP::Symbol(method), v_args, v_block);
  cObject_signal_impl(v_self, method, v_args, v_block);
  return Qnil;
}

} // namespace R_Qt
