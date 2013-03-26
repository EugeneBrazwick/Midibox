#if !defined(_URQTCORE_INTVECTOR_H_)
#define _URQTCORE_INTVECTOR_H_

// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

#include <QtCore/QVector>
#include "ruby++/array.h"
#pragma interface

namespace RPP {

class QIntVector: public Array 
{
private:
  typedef Array inherited;
public:
  QIntVector() {}
  QIntVector(E_SAFETY /*UNSAFE*/) {}
  QIntVector(const ::QVector<int> &list);
  const QVector<int> &to_q(QVector<int> &room) const;
}; // class RPP::QIntVector

} // namespace RPP 
#endif // _URQTCORE_INTVECTOR_H_
