
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

#pragma implementation

#include "stringlist.h"
#include "api_utils.h"
#include "ruby++/rppstring.h"

namespace RPP {
QStringList::QStringList(const ::QStringList &list)
{
  for (::QStringList::const_iterator i = list.constBegin(); i != list.constEnd(); ++i)
    rb_ary_push(V, R_Qt::qString2v(*i));
}

::QStringList 
QStringList::to_qstringlist() const
{
  ::QStringList retval;
  VALUE *p = ptr();
  const long N = len();
  for (long i = 0; i < N; i++, p++)
    retval << ::QString(RPP::String(*p));
  return retval;
}

} // namespace RPP 
