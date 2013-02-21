#if !defined(_RPP_OBJECT_H_)
#define _RPP_OBJECT_H_

#include "basicobject.h"

namespace RPP {

class Object: public BasicObject
{
private:
  typedef BasicObject inherited;
protected:
public:
  /* DO NOT USE. DEPRECATED. use RPP::X immediately 
  typedef RPP::ESafety ESafety;
  static const RPP::ESafety Unsafe = RPP::Unsafe;
  static const RPP::ESafety Safe = RPP::Safe;
  */
public:
  Object(VALUE v): inherited(v) {}
  /* CAUSES AMBIGUITIES
  Object(BasicObject v): inherited(v) {}
  */
  Object(): inherited() {}
  static const Object NIL;
  // these are very handy for debugging:
  const char *to_s() const { volatile VALUE s = call("to_s"); return StringValueCStr(s); }
  const char *inspect() const { volatile VALUE s = call("inspect"); return StringValueCStr(s); }
  void check_frozen() const { rb_check_frozen(V); }
  // Important: instance_eval() will pass on the block passed to the caller! (ie if rb_block_given_p())
  VALUE instance_eval() const { return rb_obj_instance_eval(0, (VALUE *)0, V); }
}; // class Object

} // namespace RPP

#endif // _RPP_OBJECT_H_

