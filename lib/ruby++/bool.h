#if !defined(_RUBYPP_BOOL_H_)
#define _RUBYPP_BOOL_H_

#include "ruby++.h"

namespace RPP {

// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

class Bool: public Object
{
private:
  typedef Object inherited;
public:
  Bool(VALUE v): inherited(v) {}
  Bool(bool v): inherited(v ? Qtrue : Qfalse) {}
public:
  operator bool() const { return RTEST(V); }
};

} // namespace RPP 
#endif // _RUBYPP_BOOL_H_
