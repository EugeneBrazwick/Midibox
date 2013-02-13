#if !defined(_RUBY_PLUSPLUS_H_)
#define _RUBY_PLUSPLUS_H_

// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

// inline macro lib that is rock solid and crash proof
// Not to mention 100 % type safe (but this currently fails)

#include <ruby/ruby.h>
#include <ruby/intern.h>

#pragma interface

namespace RPP {

class Array;
class Fixnum;

typedef VALUE (*ArgVMethod)(int argc, VALUE *argv, VALUE v_self);
typedef VALUE (*Arg0Method)(VALUE v_self);
typedef VALUE (*Arg1Method)(VALUE v_self, VALUE v_1);
typedef VALUE (*Arg2Method)(VALUE v_self, VALUE v_1, VALUE v_2);
typedef VALUE (*Arg3Method)(VALUE v_self, VALUE v_1, VALUE v_2, VALUE v_3);
typedef VALUE (*Arg4Method)(VALUE v_self, VALUE v_1, VALUE v_2, VALUE v_3, VALUE v_4);

// prefix is 'iv' (instancevar) or 'cv' (classvar) or 'gv' (globalvar) 
// note that Fixnum has ambiguous casts of ->VALUE and ->int (since VALUE == int)...
#define RPP_SETTERS(prefix) \
  void prefix##_set(const char *name, VALUE v) const { rb_##prefix##_set(V, name, v); } \
  void prefix##_set(const char *name, Fixnum v) const; /*FORWARDED*/ \
  void prefix##_set(const char *name, bool v) const { rb_##prefix##_set(V, name, v ? Qtrue : Qfalse); } \
  void prefix##_set(const char *name, int v) const { rb_##prefix##_set(V, name, INT2NUM(v)); } \
  void prefix##_set(const char *name, double v) const { rb_##prefix##_set(V, name, DBL2NUM(v)); } \
  void prefix##_set(const char *name, const char *v) const { rb_##prefix##_set(V, name, rb_str_new_cstr(v)); }

class BasicObject
{
protected:
  VALUE V;
protected:
  BasicObject(VALUE v): V(v) {}
public:
  BasicObject(): V(Qnil) {}
  // This is just what C++ will do anyway: BasicObject(const BasicObject &other): V(other.V) {}
  VALUE value() const { return V; }
  VALUE &value_ref() { return V; }
  operator VALUE() const { return V; }
  VALUE operator*() const { return V; }
  VALUE *operator &() { return &V; }
  void operator=(VALUE v) { V = v; }
  bool test() const { return RTEST(V); }
  bool isNil() const { return NIL_P(V); }
  bool isClass() const { return TYPE(V) == T_CLASS; } 
  bool isModule() const { return TYPE(V) == T_MODULE; } 
  bool isArray() const { return TYPE(V) == T_ARRAY; }
  bool isHash() const { return TYPE(V) == T_HASH; }
  bool isFixnum() const { return FIXNUM_P(V); }
  bool isSymbol() const { return SYMBOL_P(V); }
  bool isRange() const { return rb_obj_is_kind_of(V, rb_cRange); }

  // CALLS
  VALUE call(const char *method) const
    {
      return rb_funcall(V, rb_intern(method), 0);
    }
  VALUE call(const char *method, VALUE v_1) const
    {
      return rb_funcall(V, rb_intern(method), 1, v_1);
    }
  // ONLY single arg calls have some shortcuts.
  VALUE call(const char *method, bool v) const
    {
      return rb_funcall(V, rb_intern(method), 1, v ? Qtrue : Qfalse);
    }
  VALUE call(const char *method, Fixnum v) const; // FORWARDED
  VALUE call(const char *method, int v) const
    {
      return rb_funcall(V, rb_intern(method), 1, INT2NUM(v));
    }
  VALUE call(const char *method, double v) const
    {
      return rb_funcall(V, rb_intern(method), 1, DBL2NUM(v));
    }
  VALUE call(const char *method, const char *v) const
    {
      return rb_funcall(V, rb_intern(method), 1, rb_str_new_cstr(v));
    }
  VALUE call(const char *method, VALUE v_1, VALUE v_2) const
    {
      return rb_funcall(V, rb_intern(method), 2, v_1, v_2);
    }
  VALUE call(const char *method, VALUE v_1, VALUE v_2, VALUE v_3) const
    {
      return rb_funcall(V, rb_intern(method), 3, v_1, v_2, v_3);
    }
  VALUE call(const char *method, VALUE v_1, VALUE v_2, VALUE v_3, VALUE v_4) const
    {
      return rb_funcall(V, rb_intern(method), 3, v_1, v_2, v_3, v_4);
    }
  /* generic. UNSAFE
  VALUE call(const char *method, int argc, const VALUE *argv) const
    {
      return rb_funcall2(V, rb_intern(method), argc, argv);
    }
  VALUE call_public(const char *method, int argc, const VALUE *argv) const
    {
      // rb_funcall3 checks for 'public' where rb_funcall2 ignores it completely.
      return rb_funcall3(V, rb_intern(method), argc, argv);
    }
  */
  VALUE call_public(const char *method) const
    {
      return rb_funcall3(V, rb_intern(method), 0, (VALUE *)0);
    }
  VALUE call_public(const char *method, VALUE v_1) const
    {
      return rb_funcall3(V, rb_intern(method), 1, &v_1);
    }
  VALUE call_public(const char *method, Fixnum v_1) const; /* FORWARDED */
  VALUE call_public(const char *method, int i) const
    {
      const VALUE v = INT2NUM(i);
      return rb_funcall3(V, rb_intern(method), 1, &v);
    }
  VALUE call_public(const char *method, bool b) const
    {
      const VALUE v = b ? Qtrue : Qfalse;
      return rb_funcall3(V, rb_intern(method), 1, &v);
    }
  VALUE call_public(const char *method, double f) const
    {
      const VALUE v = DBL2NUM(f);
      return rb_funcall3(V, rb_intern(method), 1, &v);
    }
  VALUE call_public(const char *method, const char *s) const
    {
      const VALUE v = rb_str_new_cstr(s);
      return rb_funcall3(V, rb_intern(method), 1, &v);
    }
  VALUE call_public(const char *method, VALUE v_1, VALUE v_2) const
    {
      VALUE args[2] = { v_1, v_2 };
      return rb_funcall3(V, rb_intern(method), 2, args);
    }
  // Etc.. etc.. (?)
 
 /* WHEN NEEDED ... 
  VALUE call(const char *method, Array args); // FORWARDED
  VALUE call_public(const char *method, Array args); // FORWARDED
  */

  /* AND NOW ALL HELL BREAKS LOOSE.
   * 
   * These work like 'call', but they accept a 'block'.
   *
   * According to Eugene, the callback block always takes two arguments.
   * The first is the yielded value, the second is the last argument to this method.
   *
   * Since it happens often that only a block is passed, I added some more variations with this condition.
   */
  VALUE call_with_block(const char *method, Arg1Method callback, VALUE v_arg = Qnil) const
    {
      return rb_block_call(V, rb_intern(method), 0, (VALUE*)0, RUBY_METHOD_FUNC(callback), v_arg);
    }
  VALUE call_with_block(const char *method, Arg1Method callback, Fixnum v_arg) const; // FORWARDED
  VALUE call_with_block(const char *method, Arg1Method callback, bool arg) const
    {
      return rb_block_call(V, rb_intern(method), 0, (VALUE*)0, RUBY_METHOD_FUNC(callback), arg ? Qtrue : Qfalse);
    }
  VALUE call_with_block(const char *method, Arg1Method callback, int arg) const
    {
      return rb_block_call(V, rb_intern(method), 0, (VALUE*)0, RUBY_METHOD_FUNC(callback), INT2NUM(arg));
    }
  VALUE call_with_block(const char *method, Arg1Method callback, double arg) const
    {
      return rb_block_call(V, rb_intern(method), 0, (VALUE*)0, RUBY_METHOD_FUNC(callback), DBL2NUM(arg));
    }
  VALUE call_with_block(const char *method, Arg1Method callback, const char *arg) const
    {
      return rb_block_call(V, rb_intern(method), 0, (VALUE*)0, RUBY_METHOD_FUNC(callback), rb_str_new_cstr(arg));
    }
  VALUE call_with_block(const char *method, Arg1Method callback, VALUE v_1, VALUE v_2) const
    {
      return rb_block_call(V, rb_intern(method), 0, (VALUE*)0, RUBY_METHOD_FUNC(callback), 
			   rb_ary_new3(2, v_1, v_2));
    }
  VALUE call_with_block(const char *method, VALUE arg1, Arg1Method callback, VALUE v_arg = Qnil) const
    {
      return rb_block_call(V, rb_intern(method), 1, &arg1, RUBY_METHOD_FUNC(callback), v_arg);
    }
  VALUE call_with_block(const char *method, Fixnum arg1, Arg1Method callback, VALUE v_arg = Qnil) const; /*FORWARDED */
  VALUE call_with_block(const char *method, bool arg1, Arg1Method callback, VALUE v_arg = Qnil) const
    {
      VALUE v = arg1 ? Qtrue : Qfalse;
      return rb_block_call(V, rb_intern(method), 1, &v, RUBY_METHOD_FUNC(callback), v_arg);
    }
  VALUE call_with_block(const char *method, int arg1, Arg1Method callback, VALUE v_arg = Qnil) const
    {
      VALUE v = INT2NUM(arg1);
      return rb_block_call(V, rb_intern(method), 1, &v, RUBY_METHOD_FUNC(callback), v_arg);
    }
  VALUE call_with_block(const char *method, double arg1, Arg1Method callback, VALUE v_arg = Qnil) const
    {
      VALUE v = DBL2NUM(arg1);
      return rb_block_call(V, rb_intern(method), 1, &v, RUBY_METHOD_FUNC(callback), v_arg);
    }
  VALUE call_with_block(const char *method, const char *arg1, Arg1Method callback, VALUE v_arg = Qnil) const
    {
      VALUE v = rb_str_new_cstr(arg1);
      return rb_block_call(V, rb_intern(method), 1, &v, RUBY_METHOD_FUNC(callback), v_arg);
    }
  VALUE call_with_block(const char *method, VALUE arg1, VALUE arg2, Arg1Method callback, VALUE v_arg = Qnil) const
    {
      VALUE args[2] = { arg1, arg2 };
      return rb_block_call(V, rb_intern(method), 2, args, RUBY_METHOD_FUNC(callback), v_arg);
    }
  // etc. etc. 
  
  // This is always safe anyway:
  int to_i() const { return NUM2INT(V); }
  double to_f() const { return NUM2DBL(V); }
  VALUE iv(const char *varname) const { return rb_iv_get(V, varname); }
  RPP_SETTERS(iv);
  bool is_kind_of(VALUE klass) const { return rb_obj_is_kind_of(V, klass); }

  // avoid the next one. But it is required, sometimes.
  int type() const { return TYPE(V); }
}; // class BasicObject

class Object: public BasicObject
{
private:
  typedef BasicObject inherited;
protected:
public:
  enum ESafety { Unsafe = false, Safe = true }; // for use with constructors.
public:
  Object(VALUE v): inherited(v) {}
  Object(): inherited() {}
  static const Object NIL;
  // these are very handy for debugging:
  const char *to_s() const { VALUE s = call("to_s"); return StringValueCStr(s); }
  const char *inspect() const { VALUE s = call("inspect"); return StringValueCStr(s); }
  void check_frozen() const { rb_check_frozen(V); }
  // Important: instance_eval() will pass on the block passed to the caller! (ie if rb_block_given_p())
  VALUE instance_eval() const { return rb_obj_instance_eval(0, (VALUE *)0, V); }
}; // class Object

class Class;

class Module: public Object
{
private:
  typedef Object inherited;
  /* ??
  typedef VALUE (*ArgVFunc)(int argc, VALUE *argv, VALUE v_self);
  typedef VALUE (*Arg0Func)(VALUE v_self);
  typedef VALUE (*Arg1Func)(VALUE v_self, VALUE v_1);
  typedef VALUE (*Arg2Func)(VALUE v_self, VALUE v_1, VALUE v_2);
  typedef VALUE (*Arg3Func)(VALUE v_self, VALUE v_1, VALUE v_2, VALUE v_3);
  typedef VALUE (*Arg4Func)(VALUE v_self, VALUE v_1, VALUE v_2, VALUE v_3, VALUE v_4);
  */
protected:
public:
  Module(): inherited() {}
  Module(VALUE v): inherited(v) {}
  Module(const char *name): inherited(rb_define_module(name)) {} 
  Module define_module(const char *name) const { return rb_define_module_under(V, name); }
  Class define_class(const char *name, Class super) const;
  /* SOME EXAMPLES:
   *
   *     rb_define_method(cMyClass, "bla", RUBY_METHOD_FUNC(cMyClass_bla), -1),
   *
   *  becomes:
   *     cMyClass.define_method("bla", cMyClass_bla);
   *
   *     NOTE: 'kind' no longer used. FIXME
   */
#define RPP_FUNCBLOCK_5(definer, code, argcount, internal_definer, kind) \
  const Module &definer(const char *funcname, Arg##code##Method func) const \
    { \
      internal_definer(V, funcname, RUBY_METHOD_FUNC(func), argcount); \
      return *this; \
    }
#define RPP_FUNCBLOCK_3(definer, code, argcount) \
  RPP_FUNCBLOCK_5(definer, code, argcount, rb_##definer, Method)
#define RPP_FUNCBLOCK(definer, internal_definer) \
  RPP_FUNCBLOCK_5(definer, V, -1, internal_definer, Func) \
  RPP_FUNCBLOCK_5(definer, 0, 0, internal_definer, Func) \
  RPP_FUNCBLOCK_5(definer, 1, 1, internal_definer, Func) \
  RPP_FUNCBLOCK_5(definer, 2, 2, internal_definer, Func) \
  RPP_FUNCBLOCK_5(definer, 3, 3, internal_definer, Func) \
  RPP_FUNCBLOCK_5(definer, 4, 4, internal_definer, Func)
#define RPP_METHBLOCK(definer) \
  RPP_FUNCBLOCK_3(definer, V, -1) \
  RPP_FUNCBLOCK_3(definer, 0, 0) \
  RPP_FUNCBLOCK_3(definer, 1, 1) \
  RPP_FUNCBLOCK_3(definer, 2, 2) \
  RPP_FUNCBLOCK_3(definer, 3, 3) \
  RPP_FUNCBLOCK_3(definer, 4, 4)
  RPP_FUNCBLOCK(define_function, rb_define_module_function)
  RPP_METHBLOCK(define_private_method)
  RPP_METHBLOCK(define_method)
  RPP_METHBLOCK(define_protected_method)
  const Module &define_alias(const char *alias, const char *org) const 
    { 
      rb_define_alias(V, alias, org); 
      return *this; 
    }
  const Module &define_const(const char *name, VALUE val) const 
    {
      rb_define_const(V, name, val);
      return *this;
    }
  // etc. etc....
  VALUE cv(const char *classvarname) const { return rb_cv_get(V, classvarname); }
  RPP_SETTERS(cv)
}; // class Module

class Class: public Module
{
  friend class Module;
private:
  typedef Module inherited;
protected:
public:
  Class(): inherited() {}
  Class(VALUE v): inherited(v) {}
  //Module(const char *name): inherited(rb_define_module(name)) {} 
  static const Class Object;
  const Class &define_alloc_func(VALUE (*func)(VALUE)) const { rb_define_alloc_func(V, func); return *this; }
  VALUE new_instance() const { return rb_class_new_instance(0, (VALUE *)0, V); }
  VALUE new_instance(const Array v_1) const; // FORWARDED
  VALUE new_instance(VALUE v_1) const { return rb_class_new_instance(1, &v_1, V); }
  VALUE new_instance(bool b) const { VALUE v = b ? Qtrue : Qfalse; return rb_class_new_instance(1, &v, V); }
  VALUE new_instance(int i) const { VALUE v = INT2NUM(i); return rb_class_new_instance(1, &v, V); }
  VALUE new_instance(Fixnum i) const; // FORWARDED
  VALUE new_instance(double f) const { VALUE v = DBL2NUM(f); return rb_class_new_instance(1, &v, V); }
  VALUE new_instance(const char *s) const { VALUE v = rb_str_new_cstr(s); return rb_class_new_instance(1, &v, V); }
  VALUE new_instance(VALUE v_1, VALUE v_2) const 
    {
      VALUE args[2] = { v_1, v_2 };
      return rb_class_new_instance(2, args, V); 
    }
  VALUE new_instance(VALUE v_1, VALUE v_2, VALUE v_3) const 
    {
      VALUE args[3] = { v_1, v_2, v_3 };
      return rb_class_new_instance(3, args, V); 
    }
  VALUE new_instance(VALUE v_1, VALUE v_2, VALUE v_3, VALUE v_4) const 
    {
      VALUE args[4] = { v_1, v_2, v_3, v_4 };
      return rb_class_new_instance(4, args, V); 
    }
};

inline Class 
Module::define_class(const char *name, Class super) const 
{ 
  return rb_define_class_under(V, name, super); 
}

} // namespace RPP

#define RQT_TO_S(x) rb_funcall(x, rb_intern("to_s"), 0)
#define TO_CSTR(x) RSTRING_PTR(RQT_TO_S(x))
#define INSPECT(x) RSTRING_PTR(rb_inspect(x))

#undef RPP_SETTERS

#endif // _RUBY_PLUSPLUS_H_
