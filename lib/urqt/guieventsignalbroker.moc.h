
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

#include "urqtCore/eventsignalbroker.moc.h"
#pragma interface

namespace R_Qt {

class WidgetEventBroker: public ObjectEventBroker
{
  Q_OBJECT
private:
  typedef ObjectEventBroker inherited;
protected:
  WidgetEventBroker(QObject *parent): inherited(parent) {}
  override void event_filter(const RPP::QObject<QObject> object,
			     const QEvent &event,
			     RPP::Symbol method) const;
public:
  static VALUE signal(QEvent::Type tp, const char *method, 
		      int argc, VALUE *argv, VALUE v_self);
}; // class WidgetEventBroker

} // namespace R_Qt
