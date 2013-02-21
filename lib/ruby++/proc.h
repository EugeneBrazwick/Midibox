#if !defined(_RUBYPP_PROC_H_)
#define _RUBYPP_PROC_H_

#include "ruby++/array.h" // since rb_proc_call works only with an ary

namespace RPP {

class Range;

// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

class Proc: public Object
{
private:
  typedef Object inherited;
public:
  Proc(VALUE v, E_SAFETY safe = SAFE) { assign(v, safe); }
  override void assign(VALUE v, E_SAFETY safe)
    {
      inherited::assign(v, safe);
      if (safe == SAFE || safe == UNSAFE && !isNil())
	{
	  if (!rb_obj_is_proc(V))
	    rb_raise(rb_eTypeError, "Could not convert %s to a proc", inspect());
	}
    }
  VALUE callback(Array args) const { return rb_proc_call(V, args); }
  VALUE callback() const { return rb_proc_call(V, rb_ary_new()); }
}; // class Proc

inline Scan &
Scan::block(Proc &v)
{
  if (rb_block_given_p())
    v.assign(rb_block_proc(), VERYUNSAFE);
  else
    v.assign(Qnil, UNSAFE);
  return *this;
}

} // namespace RPP 
#endif // _RUBYPP_PROC_H_
