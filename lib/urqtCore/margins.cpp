
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

//#define TRACE

#pragma implementation

#include "margins.h"
#include "ruby++/scan.h"
#include "ruby++/array.h"

namespace R_Qt {

RPP::Class
cMargins;

static VALUE
cMargins_alloc(VALUE /*cSizeF*/)
{
  return RPP::QMargins(new QMargins);
}

void 
init_margins(RPP::Module mQt)
{
  cMargins = mQt.define_class("Margins", rb_cObject);
  cMargins.define_alloc_func(cMargins_alloc);
}

} // namespace R_Qt 

namespace RPP {
QMargins::QMargins(int argc, VALUE *argv):
inherited(Qnil, R_Qt::cMargins, UNSAFE)
{
  trace1("QMargins(argc=%d)", argc);
  Fixnum left, top, right, bottom;
  Scan scan(argc, argv);
  trace("constructed Scan, calling arg");
  scan.arg(left);
  trace("calling opts()");
  scan.opts(top, right, bottom);
  track4("Scanned %s, %s, %s, %s", left, top, right, bottom);
  if (top.isNil() && left.isArray())
    {
      const Array ary(left, VERYUNSAFE);
      switch (ary.len())
	{
	case 4:
	  bottom = ary[3];
	  right = ary[2];
	  // fall through
	case 2:
	  top = ary[1];
	  // fall through
	case 1:
	  left = ary[0];
	  break;
	default:
	  rb_raise(rb_eTypeError, "invalid arraylength for margins");
	}
    }
  if (top.isNil())
    {
      if (left.isData())
	  assign(left, SAFE);
      else
	{
	  const int l = left;
	  assignQMargins(new ::QMargins(l, l, l, l));
	}
    }
  else if (right.isNil())
    {
      const int l = left, t = top;
      assignQMargins(new ::QMargins(l, t, l, t));
    }
  else
      assignQMargins(new ::QMargins(left, top, right, bottom));
}

} // namespace RPP 
