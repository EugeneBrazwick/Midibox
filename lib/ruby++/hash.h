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
  };
public:
  Hash(): inherited(rb_hash_new()) {}
  Hash(VALUE v, ESafety safe = Safe): inherited(v)
    {
      if (safe)
	{
	  V = rb_check_hash_type(v);
	  if (NIL_P(V))
	    rb_raise(rb_eTypeError, "Could not convert %s to a hash", TO_CSTR(v));
	}
    }
  // It is possible to make it so that:
  //    hash[x] = y
  // will work too. This requires a kind of hidden C++-closure object.
  void aset(Symbol sym, VALUE v) { rb_hash_aset(V, sym, v); }
  void a_set(Symbol sym, VALUE v) { rb_hash_aset(V, sym, v); }
  void aset(const char *sym, VALUE v) { rb_hash_aset(V, Symbol(sym), v); }
  void a_set(const char *sym, VALUE v) { rb_hash_aset(V, Symbol(sym), v); }
  VALUE a(Symbol sym) const { return rb_hash_aref(V, sym); }
  VALUE a(const char *sym) const { return rb_hash_aref(V, Symbol(sym)); }
  VALUE operator[](Symbol sym) const { return rb_hash_aref(V, sym); }
  VALUE operator[](const char *sym) const { return rb_hash_aref(V, Symbol(sym)); }
  const Closure operator[](VALUE i) { return Closure(*this, i); }
  // tempting to support    operator[](const char *symname)
  // but that would be confusing since one may expect the key to be a String.
};

class Dictionary: public Hash
{
private:
  typedef Hash inherited;
public:
  Dictionary(): inherited() {}
  Dictionary(VALUE v, ESafety safe = Safe): inherited(v, safe) {}
  VALUE operator[](Symbol sym) const { return rb_hash_aref(V, sym); }
  VALUE operator[](const char *sym) const { return rb_hash_aref(V, Symbol(sym)); }
  const Closure operator[](const char *symbol) { return Closure(*this, RPP::Symbol(symbol)); }
};

} // namespace RPP 
#endif // _RUBYPP_HASH_H_
