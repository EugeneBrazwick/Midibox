
#pragma implementation

#include "ruby++.h"

namespace RPP {

void experiment2()
{
  Module m = "Experiment";
  m.define_function("f", experiment);
}

const Object Object::NIL = Qnil;
const Class Class::Object = rb_cObject;

} // namespace RPP 
