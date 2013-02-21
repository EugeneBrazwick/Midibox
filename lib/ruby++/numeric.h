#if !defined(_RUBYPP_NUMERIC_H_)
#define _RUBYPP_NUMERIC_H_

#include "ruby++.h"

namespace RPP {

// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

class Numeric: public Object
{
private:
  typedef Object inherited;
protected:
  Numeric() {}
  Numeric(VALUE v): inherited(v) {}
public:
  // Same as to_i:
  operator int() const { return NUM2INT(V); }
  // Same as to_f:
  operator double() const { return NUM2DBL(V); }
};

class Fixnum: public Numeric
{
private:
  typedef Numeric inherited;
public:
  Fixnum(): inherited(INT2NUM(0)) {}
  Fixnum(VALUE v): inherited(v) {}
  Fixnum(int i): inherited(INT2NUM(i)) {}
  Fixnum(long l): inherited(LONG2NUM(l)) {}
  int to_i() const { return NIL_P(V) ? 0 : NUM2INT(V); }
  long to_l() const { return NIL_P(V) ? 0L : NUM2LONG(V); }
  operator int() const { return to_i(); }
  operator long() const { return to_l(); }
  VALUE operator*() const { return V; }
  long operator*(long l) const { return to_l() * l; }
  long operator/(long l) const { return to_l() / l; }
  long operator%(long l) const { return to_l() % l; }
  long operator+(long l) const { return to_l() + l; }
  long operator-(long l) const { return to_l() - l; }
};

class Float: public Numeric
{
private:
  typedef Numeric inherited;
public:
  Float(): inherited(DBL2NUM(0.0)) {}
  Float(VALUE v): inherited(v) {}
  Float(double d): inherited(DBL2NUM(d)) {}
  VALUE operator*() const { return V; }
  double operator*(double f) const { return to_f() * f; }
  double operator/(double f) const { return to_f() / f; }
  double operator+(double f) const { return to_f() + f; }
  double operator-(double f) const { return to_f() - f; }
  double to_f() const { return NIL_P(V) ? 0.0 : NUM2DBL(V); }
  operator double() const { return to_f(); }
};

inline const BasicObject &
BasicObject::iv_set(const char *name, Fixnum v) const { rb_iv_set(V, name, v); return *this; }

inline const Module &
Module::cv_set(const char *name, Fixnum v) const { rb_cv_set(V, name, v); return *this; }

inline VALUE 
BasicObject::call(const char *method, Fixnum v_1) const 
{ 
  return rb_funcall(V, rb_intern(method), 1, *v_1);
}

inline VALUE 
BasicObject::call_public(const char *method, Fixnum v_1) const { return rb_funcall3(V, rb_intern(method), 1, &v_1); }

inline VALUE 
BasicObject::call_with_block(const char *method, Fixnum arg1, Arg1Method callback, VALUE v_arg) const
{ 
  return rb_block_call(V, rb_intern(method), 1, &arg1, RUBY_METHOD_FUNC(callback), v_arg); 
}

inline VALUE 
BasicObject::call_with_block(const char *method, Arg1Method callback, Fixnum v_arg) const
{ 
  return rb_block_call(V, rb_intern(method), 0, (VALUE *)0, RUBY_METHOD_FUNC(callback), v_arg); 
}

inline const Module &
Module::define_const(const char *name, Fixnum val) const
{
  return define_const(name, *val);
}

inline const Module &
Module::define_cv(const char *name, Fixnum val) const
{
  return define_cv(name, *val);
}

inline  VALUE 
Class::new_instance(Fixnum i) const
{ 
  VALUE v = i; 
  return rb_class_new_instance(1, &v, V); 
}

} // namespace RPP 
#endif // _RUBYPP_NUMERIC_H_
