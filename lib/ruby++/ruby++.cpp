
#pragma implementation

#include "ruby++.h"
// not required, but errors in templates are then reveiled
#include "hash.h"
#include "numeric.h"
#include "dataobject.h"
#include "range.h"
#include "array.h"
#include "proc.h"
#include "bool.h"

namespace RPP {

const Object Object::NIL = Qnil;
const Class Class::Object = rb_cObject;

} // namespace RPP 
