#if !defined (_URQT_OBJECT_H_)
#define _URQT_OBJECT_H_

// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

#include "ruby++/ruby++.h" 
#include "api_utils.h" /* "rather unavoidable" */
#pragma interface

namespace R_Qt {
extern RPP::Module mQt, mR; 
extern VALUE cSynthObject, cDynamicAttribute;

extern void cObject_mark(QObject *object);
extern VALUE cObject_signal_implementation(VALUE v_self, VALUE v_method, VALUE v_signal,
					   VALUE v_args, VALUE v_block);
extern void cObject_initialize_arg(VALUE v_self, VALUE v_arg);

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

// ANY T_DATA instance
static inline void
ZOMBIFY(VALUE v)
{
  DATA_PTR(v) = 0;
}

static inline bool
IS_ZOMBIFIED(VALUE v)
{
  return DATA_PTR(v) == 0;
}

/* This class behaves similar to VALUE except that the Garbage Collector will
automatically leave it alone.
*/
class GCSafeValue
{
private:
  VALUE V;
public:
  GCSafeValue(VALUE v): V(v) { rb_gc_register_address(&V); }
  ~GCSafeValue() { rb_gc_unregister_address(&V); }
  VALUE operator ->() const { return V; }
  VALUE operator *() const { return V; }
  operator VALUE() const { return V; }
};

} // namespace R_Qt 

extern "C" void Init_liburqtCore();

#endif // _URQT_OBJECT_H_
