#if !defined(_RUBYPP_STRING_H_)
#define _RUBYPP_STRING_H_

#include "ruby++.h"
#include <ruby/encoding.h>

namespace RPP {

// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick
class String: public Object
{
private:
  typedef Object inherited;
public:
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
};

class Symbol: public Object
{
private:
  typedef Object inherited;
public:
  Symbol(VALUE v, ESafety safe = Safe): inherited(v)
    {
      if (safe && TYPE(V) != T_SYMBOL)
	rb_raise(rb_eTypeError, "attempt to cast %s to a Symbol", inspect());
    }
  Symbol(const char *cstr): inherited(ID2SYM(rb_intern(cstr))) {}
  ID to_id() const { return SYM2ID(V); }
};

} // namespace RPP 
#endif // _RUBYPP_STRING_H_
