#if !defined(_RPP_CLASS_H_)
#define _RPP_CLASS_H_

#include "ruby++/module.h"

namespace RPP {

class Class: public Module
{
  friend class Module;
private:
  typedef Module inherited;
protected:
public:
  Class(): inherited() {}
  Class(VALUE v): inherited(v) {}
  Class(const char *name, VALUE super = rb_cObject): inherited(rb_define_class(name, super)) {} 
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
#endif // _RPP_CLASS_H_
