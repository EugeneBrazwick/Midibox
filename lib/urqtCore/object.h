#if !defined (_URQT_OBJECT_H_)
#define _URQT_OBJECT_H_

// #include "ruby++/ruby++.h"
#pragma interface

namespace R_Qt {
extern VALUE mQt, mR;

extern void cObject_mark(QObject *object);
extern VALUE cObject_signal_implementation(VALUE v_self, VALUE v_method, VALUE v_signal,
					   VALUE v_args, VALUE v_block);
// cannot be overloaded!
static inline void 
cObject_signal_impl(VALUE v_self, const char *method, VALUE v_args, 
		    VALUE v_block)
{
  const VALUE v_method = ID2SYM(rb_intern(method));
  cObject_signal_implementation(v_self, v_method, v_method, v_args, v_block);
}

static inline VALUE 
cObjectWrap(VALUE klass, QObject *object)
{
  return Data_Wrap_Struct(klass, cObject_mark, 0, object);
}
} // namespace R_Qt 

extern "C" void Init_liburqtCore();

#endif // _URQT_OBJECT_H_
