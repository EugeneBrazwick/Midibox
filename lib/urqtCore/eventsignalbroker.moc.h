#if !defined(_URQTCORE_EVSIGBROKER_H_)
#define _URQTCORE_EVSIGBROKER_H_

// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

#include "urqtCore/object.h"
#include <QtCore/QEvent>
#include "ruby++/symbol.h"
#pragma interface

namespace R_Qt {

class ObjectEventBroker: public QObject
{
  Q_OBJECT    /* required for storage inside QVariant */
private:
  typedef QObject inherited;
  // map event types to ruby callbacks
  QHash<QEvent::Type, const char *>Events;
protected:
  virtual void event_filter(const RPP::QObject<QObject> object, const QEvent &event, 
			    RPP::Symbol v_method) const;
  override bool eventFilter(QObject *object, QEvent *event);
  ObjectEventBroker(QObject *parent);
  void registerEvent(QEvent::Type tp, const char *method);
  static const char ESB_PropertyId[];
public:
  /* Example:
   *
   * cObject_childAdded(int argc, VALUE *argv, VALUE v_self)
   * {
   *   return ObjectEventBroker::signal(QEvent::ChildAdded, "childAdded", argc, argv, v_self);
   * }
   *
   * cWidget_shown(int argc, VALUE *argv, VALUE v_self)
   * {
   *   return WidgetEventBroker::signal(QEvent::Show, "shown", argc, argv, v_self);
   * }
   *
   * ObjectEventBroker is in urqtCore, and WidgetEventBroker should be used for urqt.
   *
   * IMPORTANT: this does 'connect' if a block was passed, and each call will ADD
   * to the callbackset of the signal (== method).
   *
   * IMPORTANT: uses ruby native signal system and not Qt's signals/slots!
   */
  static VALUE signal(QEvent::Type tp, const char *method, int argc, VALUE *argv, VALUE v_self);
}; // class ObjectEventBroker

} // namespace R_Qt 

#endif // _URQTCORE_EVSIGBROKER_H_
