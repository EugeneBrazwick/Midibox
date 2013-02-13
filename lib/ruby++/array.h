#if !defined(_RUBYPP_ARRAY_H_)
#define _RUBYPP_ARRAY_H_

#include "numeric.h"

namespace RPP {

class Range;

// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

class Array: public Object
{
private:
  typedef Object inherited;
  class Closure {
    private:
      const Array &Ary;
      const VALUE Index; // but it can be a range as well
      const VALUE Length; // optional
      const bool HasLength;
    private:
      void assign(VALUE arg) const
	{
	  if (HasLength)
	    Ary.call("[]=", Index, Length, arg);
	  else
	    Ary.call("[]=", Index, arg);
	}
    public:
      Closure(const Array &ary, VALUE i): Ary(ary), Index(i), Length(Qnil), HasLength(false) {}
      Closure(const Array &ary, VALUE i, VALUE len): Ary(ary), Index(i), Length(len), HasLength(true) {}
      void operator=(VALUE arg) const { assign(arg); }
      void operator=(bool arg) const { assign(arg ? Qtrue: Qfalse); }
      void operator=(int arg) const { assign(INT2NUM(arg)); }
      void operator=(Fixnum arg) const { assign(arg); }
      void operator=(double arg) const { assign(DBL2NUM(arg)); }
      void operator=(const char *arg) const { assign(rb_str_new_cstr(arg)); }
  };
public:
  enum ECreateSingleton { CreateSingleton };
public:
  Array(): inherited(rb_ary_new()) {}
  // VERY BAD IDEA  Array(VALUE v_1): inherited(rb_ary_new3(1, v_1)) {}
  Array(VALUE v_1, ECreateSingleton): inherited(rb_ary_new3(1, v_1)) {}
  Array(bool b): inherited(rb_ary_new3(1, b ? Qtrue : Qfalse)) {}
  Array(int i): inherited(rb_ary_new3(1, INT2NUM(i))) {}
  Array(Fixnum i): inherited(rb_ary_new3(1, i)) {}
  Array(double f): inherited(rb_ary_new3(1, DBL2NUM(f))) {}
  Array(const char *s): inherited(rb_ary_new3(1, rb_str_new_cstr(s))) {}
  Array(VALUE v_1, VALUE v_2): inherited(rb_ary_new3(2, v_1, v_2)) {}
  Array(VALUE v_1, VALUE v_2, VALUE v_3): inherited(rb_ary_new3(3, v_1, v_2, v_3)) {}
  Array(VALUE v_1, VALUE v_2, VALUE v_3, VALUE v_4): inherited(rb_ary_new3(4, v_1, v_2, v_3, v_4)) {}
  Array(VALUE v, ESafety safe = Safe): inherited(v)
    {
      if (safe)
	{
	  V = rb_check_array_type(v);
	  if (NIL_P(V))
	    rb_raise(rb_eTypeError, "Could not convert %s to an array", TO_CSTR(v));
	}
    }

  // The following is unsafe, but required for some internal argument hocus pocus
  Array(int argc, VALUE *argv): inherited(rb_ary_new4(argc, argv)) {}

  // Note that 'slice' is very safe. And negative indices work as expected
  /*  VALUE slice(int index) const { Fixnum f = index; return rb_ary_aref(1, &f, V); } 
   *	  USE at()
   */
  VALUE slice(int start, int len) const 
    { 
      VALUE v[2] = { INT2NUM(start), INT2NUM(len) }; 
      return rb_ary_aref(2, v, V); 
    }
  // arg1 can be a Range or a Fixnum
  VALUE slice(VALUE arg1) const { return rb_ary_aref(1, &arg1, V); } 
  VALUE at(VALUE pos) const { return call("at", pos); }
  VALUE at(int pos) const { return call("at", Fixnum(pos)); }
  VALUE at(Fixnum pos) const { return call("at", pos); }
  VALUE operator[](VALUE i) const { return at(i); }
  VALUE operator[](int i) const { return at(i); }
  VALUE operator[](Fixnum i) const { return at(i); }
  const Closure operator[](VALUE i) { return Closure(*this, i); }
  const Closure operator[](int i) { return (*this)[Fixnum(i)]; }
  const Closure operator[](Fixnum i) { return (*this)[i]; }
  // For fast and very C-like access use length() and ptr().
  int length() const { return RARRAY_LEN(V); }
  VALUE *ptr() const { return RARRAY_PTR(V); }
};

inline VALUE
Class::new_instance(const Array v_1) const
{
  return rb_class_new_instance(v_1.length(), v_1.ptr(), V);
}

} // namespace RPP 
#endif // _RUBYPP_ARRAY_H_
