#if !defined (_URQT_OBJECT_H_)
#define _URQT_OBJECT_H_

// #include "ruby++/ruby++.h"
#pragma interface

namespace R_Qt {
extern VALUE mQt, mR;
extern VALUE cObject;

extern void cObject_mark(QObject *object);

static inline VALUE cObjectWrap(VALUE klass, QObject *object)
{
  return Data_Wrap_Struct(klass, cObject_mark, 0, object);
}
} // namespace R_Qt 

extern "C" void Init_liburqtCore();

#endif // _URQT_OBJECT_H_
