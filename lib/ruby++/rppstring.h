#if !defined(_RUBYPP_STRING_H_)
#define _RUBYPP_STRING_H_

// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

#include "ruby++.h"
#include "numeric.h"
#include <ruby/encoding.h>

namespace RPP {

class String: public Object
{
private:
  typedef Object inherited;
public:
  String(): inherited(rb_str_new_cstr("")) {}
  String(VALUE v): inherited(v) 
    {
    }
  String(const char *cstr): inherited(rb_str_new_cstr(cstr)) {}
  String to_utf8() const 
    { 
      Check_Type(V, T_STRING);
      static const int enc = rb_enc_find_index("UTF-8");
      rb_enc_associate_index(V, enc);
      return *this;
    }
  operator const char *() const { volatile VALUE tmp = V; return StringValueCStr(tmp); }
  operator const char *() { return StringValueCStr(V); }
  bool isEmpty() const { return RTEST(call("empty?")); }
  // This is meant for quickies. Notice that ruby only supports String args!
  const String &operator << (VALUE v) const { call("<<", RPP::Object(v).to_s()); return *this; }
  const String &operator << (bool v) const { return *this << (v ? Qtrue : Qfalse); }
  const String &operator << (int v) const { return *this << INT2NUM(v); }
  const String &operator << (Fixnum v) const { return *this << VALUE(v); }
  const String &operator << (double v) const { return *this << DBL2NUM(v); }
  const String &operator << (const char *v) const { return *this << rb_str_new_cstr(v); }
};

class Symbol: public Object
{
private:
  typedef Object inherited;
public:
  Symbol(VALUE v, E_SAFETY safe = SAFE): inherited(v)
    {
      if ((safe == SAFE || safe == UNSAFE && !isNil()) && !SYMBOL_P(V))
	rb_raise(rb_eTypeError, "attempt to cast %s to a Symbol", inspect());
    }
  Symbol(const char *cstr): inherited(ID2SYM(rb_intern(cstr))) {}
  Symbol(): Symbol("nil") {}
  ID to_id() const { return SYM2ID(V); }
  bool operator==(const char *other) const { return to_id() == rb_intern(other); } 
  bool operator!=(const char *other) const { return to_id() != rb_intern(other); } 
};

inline RPP::String 
BasicObject::check_string_type() const 
{ 
  return rb_check_string_type(V); 
}

inline RPP::String
Object::to_str() const
{
  return rb_str_to_str(V);
}

} // namespace RPP 
#endif // _RUBYPP_STRING_H_
