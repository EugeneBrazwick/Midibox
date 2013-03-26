
#pragma implementation

// not required, but errors in templates are then reveiled
#include "ruby++all.h"

namespace RPP {

const Object Object::NIL = Qnil;
const Class Class::Object = rb_cObject;

} // namespace RPP 
