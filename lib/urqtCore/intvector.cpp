
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

#pragma implementation

#include "intvector.h"

namespace RPP {
QIntVector::QIntVector(const ::QVector<int> &list)
{
  for(::QVector<int>::const_iterator i = list.constBegin(); i != list.constEnd(); ++i)
    rb_ary_push(V, RPP::Fixnum(*i));
}

const QVector<int> &
QIntVector::to_q(QVector<int> &room) const
{
  VALUE *p = ptr();
  for (long N = len(), i = 0; i < N; i++, p++)
    room << RPP::Fixnum(*p);
  return room;
}

} // namespace RPP 
