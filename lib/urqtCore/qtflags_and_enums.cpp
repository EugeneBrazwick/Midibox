
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

#pragma implementation
#include "qtflags_and_enums.h"
#include "object.h"
#include "ruby++/hash.h"

namespace R_Qt {
Qt::Alignment
alsyms2qtalignment(RPP::Array alsyms)
{
  if (alsyms.isNil()) return Qt::Alignment(0); // for convenience
  Qt::Alignment al;
  VALUE *v = alsyms.ptr();
  RPP::Dictionary dct(mQt.cv("@@alignmentflags"), RPP::VERYUNSAFE);
  if (!dct.isHash())
    {
      mQt.cv_set("@@alignmentflags", dct = RPP::Dictionary());
#define ENTRY_DO(sym, enumval) dct[#sym] = RPP::Fixnum(Qt::Align##enumval)
      ENTRY_DO(left, Left);
      ENTRY_DO(right, Right);
      ENTRY_DO(center, HCenter);
      ENTRY_DO(hcenter, HCenter);
      ENTRY_DO(vcenter, HCenter);
      ENTRY_DO(top, Top);
      ENTRY_DO(bottom, Bottom);
      ENTRY_DO(absolute, Absolute);
      ENTRY_DO(leading, Leading); // == left
      ENTRY_DO(trailing, Trailing); // == right
#undef ENTRY_DO
    }
  for (long i = 0, l = alsyms.len(); i < l; i++, v++)
    al |= Qt::AlignmentFlag(RPP::Fixnum(dct[*v]).to_i());
  return al;
}

} // namespace R_Qt
