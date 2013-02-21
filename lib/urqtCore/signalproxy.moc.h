
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

#include <QtCore/QObject>
#include <QtCore/QVariant>
#include "rvalue.h"
#include "ruby++/array.h"
#include "object.h"

#pragma interface

namespace R_Qt {

class QSignalProxy: public QObject
{
  Q_OBJECT
private:
  typedef QObject inherited;
  GCSafeValue Block;
  const QByteArray QSig;
  const char * const Signal; // same as QSig.data
private:
  void handle_i(RPP::Array v_ary) const;
  VALUE block() const { return Block; }
private slots:
  // These are (currently) the available brokers:
  void handle() const;
  void handle(QObject *) const;
  void handle(bool) const;
  void handle(int) const;
public:
  QSignalProxy(QObject *parent, const char *signal, VALUE v_block);
};
} // namespace R_Qt 
