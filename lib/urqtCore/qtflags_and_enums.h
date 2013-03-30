#if !defined(_URQT_QTFLAGS_H_)
#define _URQT_QTFLAGS_H_

// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

#include "ruby++/array.h"
#include <QtCore/qnamespace.h>
#pragma interface

namespace R_Qt {

extern Qt::Alignment alsyms2qtalignment(RPP::Array alsyms);


} // namespace R_Qt 

#endif // _URQT_QTFLAGS_H_
