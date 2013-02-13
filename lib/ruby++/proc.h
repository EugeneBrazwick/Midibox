#if !defined(_RUBYPP_PROC_H_)
#define _RUBYPP_PROC_H_

#include "array.h" // since rb_proc_call works only with an ary

namespace RPP {

class Range;

// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

class Proc: public Object
{
private:
  typedef Object inherited;
public:
  Proc(VALUE v, bool safe = Safe): inherited(v)
    {
      if (safe)
	{
	  if (!rb_obj_is_proc(V))
	    rb_raise(rb_eTypeError, "Could not convert %s to a proc", inspect());
	}
    }
  VALUE callback(Array args) const { return rb_proc_call(V, args); }
};

} // namespace RPP 
#endif // _RUBYPP_PROC_H_
