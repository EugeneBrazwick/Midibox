
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

#include "object.h"
#pragma interface

namespace R_Qt {

class QTimeoutHandler: public QObject
{
  Q_OBJECT
private:
  typedef QObject inherited;
  bool SingleShot;
  GCSafeValue Block;
private:
  //VALUE block() const { return Block; }
public:
  enum EShot { Multi, Single };
public:
  QTimeoutHandler(VALUE v_block, EShot singleshot = Single, QObject *parent = 0);
public slots:
  void handle();
};

} // namespace R_Qt
