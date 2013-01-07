#if !defined(_RUBY_PLUSPLUS_H_)
#define _RUBY_PLUSPLUS_H_

// inline macro lib that is rock solid and crash proof
// Not to mention 100 % type safe (but this currently fails)

#include <ruby/ruby.h>
#include <ruby/intern.h>
#include <ruby/encoding.h>

#pragma interface

namespace RPP {

// Copying VALUE like this causes unexplained crashes. DO NOT USE THIS CODE
class Value {
protected:
  VALUE V;
protected:
  Value(VALUE v = Qnil): V(v) {}
  VALUE operator*() const { return V; }
public:
  Value(const Value &other): V(other.V) {}
  operator VALUE() const { return V; }
  VALUE *operator &() { return &V; }
}; // class Value

class Object: public Value
{
private:
  typedef Value inherited;
protected:
  Object(VALUE v): inherited(v) {}
public:
  Object(): inherited() {}
  static const Object NIL;
};

class Class;

class Module: public Object
{
private:
  typedef Object inherited;
  typedef Object (*ArgVMethod)(int argc, VALUE *argv, Object v_self);
  typedef Object (*Arg0Method)(Object v_self);
  typedef Object (*Arg1Method)(Object v_self, VALUE v_1);
  typedef Object (*Arg2Method)(Object v_self, VALUE v_1, VALUE v_2);
  typedef Object (*ArgVFunc)(int argc, VALUE *argv, Module v_self);
  typedef Object (*Arg0Func)(Module v_self);
  typedef Object (*Arg1Func)(Module v_self, VALUE v_1);
  typedef Object (*Arg2Func)(Module v_self, VALUE v_1, VALUE v_2);
protected:
  Module(VALUE v): inherited(v) {}
public:
  Module(): inherited() {}
  Module(const char *name): inherited(rb_define_module(name)) {} 
  Module define_module(const char *name) const { return rb_define_module_under(V, name); }
  Class define_class(const char *name, Class super) const;
#define RPP_FUNCBLOCK_5(definer, code, argcount, internal_definer, kind) \
  void definer(const char *funcname, Arg##code##kind func) const \
    { \
      internal_definer(V, funcname, RUBY_METHOD_FUNC(func), argcount); \
    }
#define RPP_FUNCBLOCK_3(definer, code, argcount) \
  RPP_FUNCBLOCK_5(definer, code, argcount, rb_##definer, Method)
#define RPP_FUNCBLOCK(definer, internal_definer) \
  RPP_FUNCBLOCK_5(definer, V, -1, internal_definer, Func) \
  RPP_FUNCBLOCK_5(definer, 0, 0, internal_definer, Func) \
  RPP_FUNCBLOCK_5(definer, 1, 1, internal_definer, Func) \
  RPP_FUNCBLOCK_5(definer, 2, 2, internal_definer, Func)
#define RPP_METHBLOCK(definer) \
  RPP_FUNCBLOCK_3(definer, V, -1) \
  RPP_FUNCBLOCK_3(definer, 0, 0) \
  RPP_FUNCBLOCK_3(definer, 1, 1) \
  RPP_FUNCBLOCK_3(definer, 2, 2)
  RPP_FUNCBLOCK(define_function, rb_define_module_function)
  RPP_METHBLOCK(define_private_method)
  RPP_METHBLOCK(define_protected_method)
};

class Class: public Module
{
  friend class Module;
private:
  typedef Module inherited;
protected:
  Class(VALUE v): inherited(v) {}
public:
  Class(): inherited() {}
  //Module(const char *name): inherited(rb_define_module(name)) {} 
  static const Class Object;
};


inline Class Module::define_class(const char *name, Class super) const 
{ 
  return rb_define_class_under(V, name, super); 
}

template<class T> class DataObject: public Object
{
private:
  typedef Object inherited;
  T *Wrapped;
public:
    // TYPE IS NOT SAFE!! Only use for v_self!!
  DataObject<T>(VALUE v): 
    inherited(v)
    {
      Data_Get_Struct(v, T, Wrapped);
      if (!Wrapped) rb_raise(rb_eTypeError, "attempt to access a zombie");
    }
  T *operator->() const { return Wrapped; }
  operator T*() const { return Wrapped; }
};

class String: public Object
{
private:
  typedef Object inherited;
public:
  String(const char *cstr): inherited(rb_str_new_cstr(cstr)) {}
  String to_utf8() const 
    { 
      static const int enc = rb_enc_find_index("UTF-8");
      rb_enc_associate_index(V, enc);
      return *this;
    }
};

// EPIC FAIL HERE
inline Object experiment(int, VALUE *, Module v_self)
{
  return v_self;
}

extern void experiment2();
} // namespace RPP

#endif // _RUBY_PLUSPLUS_H_
