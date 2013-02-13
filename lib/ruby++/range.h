#if !defined(_RUBYPP_RANGE_H_)
#define _RUBYPP_RANGE_H_

#include "ruby++.h"

namespace RPP {

// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

class Range: public Object
{
private:
  typedef Object inherited;
  VALUE BegP;
  VALUE EndP;
  int ExclP;
public:
  Range(VALUE v, bool safe = true): inherited(v) 
    {
      const bool isRng = isRange();
      if (safe && !isRng)
	rb_raise(rb_eTypeError, "tried to cast %s to a range", inspect());
      if (isRng)
	rb_range_values(V, &BegP, &EndP, &ExclP);
    }
  // Do not call the following in unsafe mode, unless isRange() is actually checked first!
  // This is common sense, he says.
  VALUE beg() const { return BegP; }
  VALUE end() const { return EndP; }
  bool isExcl() const { return ExclP; }
  /* Note:    (4..3).beg -> 4
              (4..3).min -> nil 
              (3...5).end -> 5
              (3...5).max -> 4
              (3.2 .. 4.5).max -> 4.5
              (3.2 ... 4.5).max -> TypeError

    So use min() and max(), but they cost a rb-call!!
  */ 
  VALUE min() const { return call("min"); }
  VALUE max() const { return call("max"); }
};

} // namespace RPP 

#endif // _RUBYPP_RANGE_H_
