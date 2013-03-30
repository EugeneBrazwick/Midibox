#if !defined(_RUBYPP_REGEXP_H_)
#define _RUBYPP_REGEXP_H_

// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

#include "object.h"

namespace RPP {

class Regexp: public Object
{
private:
  typedef Object inherited;
public:
  Regexp(VALUE v, E_SAFETY safe = SAFE): inherited(v)
    {
      if ((safe == SAFE || safe == UNSAFE && !isNil()) && TYPE(V) != T_REGEXP)
	rb_raise(rb_eTypeError, "attempt to cast %s to a Regexp", inspect());
    }
  Regexp(const char *cstr)
    {
      VALUE s = rb_str_new_cstr(cstr);
      assign(rb_class_new_instance(1, &s, rb_cRegexp), RPP::VERYUNSAFE);
    }
}; // class Regexp

} // namespace RPP 
#endif // _RUBYPP_REGEXP_H_
