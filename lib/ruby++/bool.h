#if !defined(_RUBYPP_BOOL_H_)
#define _RUBYPP_BOOL_H_

#include "ruby++.h"

namespace RPP {

// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

class Bool: public Object
{
private:
  typedef Object inherited;
public:
  Bool(VALUE v): inherited(v) {}
  Bool(bool v): inherited(v ? Qtrue : Qfalse) {}
public:
  operator bool() const { return RTEST(V); }
};

} // namespace RPP 

#define RPP_DECL_BOOL_READER(rpp_class, rpp_method, cpp_class, cpp_method) \
static VALUE \
rpp_class##_##rpp_method##_p(VALUE v_self) \
{ \
  return RPP::Bool(cpp_class(v_self)->cpp_method()); \
}

#define RPP_DECL_BOOL_WRITER(rpp_class, rpp_method, cpp_class, cpp_method) \
static VALUE \
rpp_class##_##rpp_method##_set(VALUE v_self, VALUE v) \
{ \
  const cpp_class self = v_self; \
  self.check_frozen(); \
  self->cpp_method(RPP::Bool(v)); \
  return v; \
}

#define RPP_DECL_BOOL_ACCESSOR(rpp_class, rpp_method, cpp_class, cpp_method) \
  RPP_DECL_BOOL_READER(rpp_class, rpp_method, cpp_class, cpp_method) \
  RPP_DECL_BOOL_WRITER(rpp_class, rpp_method, cpp_class, cpp_method)

#define RPP_DECL_BOOL_ACCESSOR2(rpp_class, rpp_method, cpp_class, cpp_method_get, \
				cpp_method_set) \
  RPP_DECL_BOOL_READER(rpp_class, rpp_method, cpp_class, cpp_method_get) \
  RPP_DECL_BOOL_WRITER(rpp_class, rpp_method, cpp_class, cpp_method_set)

#endif // _RUBYPP_BOOL_H_
