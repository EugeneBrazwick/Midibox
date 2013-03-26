#if !defined(_RUBYPP_HASH_H_)
#define _RUBYPP_HASH_H_

#include "rppstring.h"
#include "numeric.h"

namespace RPP {

// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

class Hash: public Object
{
private:
  typedef Object inherited;
protected:
  class Closure {
    private:
      const Hash &Hsh;
      VALUE Index; // can be any class
    public:
      Closure(const Hash &hash, VALUE i): Hsh(hash), Index(i) {}
      void operator=(VALUE arg) const { rb_hash_aset(Hsh, Index, arg); }
      // etc.
      void operator=(bool arg) const { rb_hash_aset(Hsh, Index, arg ? Qtrue : Qfalse); }
      void operator=(int arg) const { rb_hash_aset(Hsh, Index, INT2NUM(arg)); }
      void operator=(Fixnum arg) const { rb_hash_aset(Hsh, Index, arg); }
      void operator=(double arg) const { rb_hash_aset(Hsh, Index, DBL2NUM(arg)); }
      void operator=(const char *arg) const { rb_hash_aset(Hsh, Index, rb_str_new_cstr(arg)); }
      // etc. etc.
      //
      operator VALUE() const 
	{
	  return rb_hash_aref(Hsh, Index);
	}
  };
public:
  Hash(): inherited(rb_hash_new()) {}
  Hash(VALUE v, E_SAFETY safe = SAFE) { assign(v, safe); }
  override void assign(VALUE v, E_SAFETY safe = SAFE)
    {
      inherited::assign(v, safe);
      if (safe == SAFE || safe == UNSAFE && !isNil())
	{
	  V = rb_check_hash_type(V);
	  if (NIL_P(V))
	    rb_raise(rb_eTypeError, "Could not convert %s to a hash", TO_CSTR(v));
	}
    }
  void aset(Symbol sym, VALUE v) { rb_hash_aset(V, sym, v); }
  void a_set(Symbol sym, VALUE v) { rb_hash_aset(V, sym, v); }
  void aset(const char *str, VALUE v) { rb_hash_aset(V, String(str), v); }
  void a_set(const char *str, VALUE v) { rb_hash_aset(V, String(str), v); }
  VALUE a(Symbol sym) const { return rb_hash_aref(V, sym); }
  VALUE a(const char *str) const { return rb_hash_aref(V, String(str)); }
  VALUE a(VALUE v) const { return rb_hash_aref(V, v); }
  VALUE operator[](Symbol sym) const { return a(sym); }
  VALUE operator[](const char *str) const { return a(str); }
  VALUE operator[](VALUE v) const { return a(v); }
  const Closure operator[](Symbol sym) { return Closure(*this, sym); }
  const Closure operator[](const char *s) { return Closure(*this, String(s)); }
  const Closure operator[](VALUE v) { return Closure(*this, v); }
  // tempting to support    operator[](const char *symname)
  // but that would be confusing since one may expect the key to be a String.
}; // class Hash

class Dictionary: public Hash
{
private:
  typedef Hash inherited;
public:
  Dictionary(): inherited() {}
  Dictionary(VALUE v, E_SAFETY safe = SAFE): inherited(v, safe) {}
  VALUE operator[](Symbol sym) const { return rb_hash_aref(V, sym); }
  VALUE operator[](const char *sym) const { return rb_hash_aref(V, Symbol(sym)); }
  const Closure operator[](const char *symbol) { return Closure(*this, RPP::Symbol(symbol)); }
};

} // namespace RPP 
#endif // _RUBYPP_HASH_H_
