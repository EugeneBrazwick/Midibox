#if !defined(_URQTCORE_STRLIST_H_)
#define _URQTCORE_STRLIST_H_

// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

#include <QtCore/QStringList>
#include "ruby++/array.h"
#pragma interface

namespace RPP {

class QStringList: public Array 
{
private:
  typedef Array inherited;
public:
  QStringList(const ::QStringList &list);
  ::QStringList to_qstringlist() const;
  operator ::QStringList() const { return to_qstringlist(); }
}; // class RPP::QStringList

} // namespace RPP 
#endif // _URQTCORE_STRLIST_H_
