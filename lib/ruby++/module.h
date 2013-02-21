#if !defined(_RPP_MODULE_H_)
#define _RPP_MODULE_H_

#include "ruby++/object.h"

namespace RPP {

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
  const Module &define_const(const char *name, int val) const { return define_const(name, INT2NUM(val)); }
  const Module &define_const(const char *name, Fixnum val) const; // FORWARDED
  const Module &define_const(const char *name, bool val) const { return define_const(name, val ? Qtrue : Qfalse); }
  const Module &define_const(const char *name, double val) const { return define_const(name, DBL2NUM(val)); }
  const Module &define_const(const char *name, const char *val) const { return define_const(name, rb_str_new_cstr(val)); }
  // etc. etc....
  const Module &define_cv(const char *name, VALUE val) const 
    {
      rb_define_class_variable(V, name, val);
      return *this;
    }
  const Module &define_cv(const char *name, int val) const { return define_cv(name, INT2NUM(val)); }
  const Module &define_cv(const char *name, Fixnum val) const; // FORWARDED
  const Module &define_cv(const char *name, bool val) const { return define_cv(name, val ? Qtrue : Qfalse); }
  const Module &define_cv(const char *name, double val) const { return define_cv(name, DBL2NUM(val)); }
  const Module &define_cv(const char *name, const char *val) const { return define_cv(name, rb_str_new_cstr(val)); }
  // etc. etc....
  VALUE cv(const char *classvarname) const { return rb_cv_get(V, classvarname); }
  RPP_SETTERS(Module, cv)
}; // class Module

} // namespace RPP
#endif // _RPP_MODULE_H_
