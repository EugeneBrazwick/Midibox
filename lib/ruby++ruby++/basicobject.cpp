
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

#pragma implementation

//#define TRACE

#include "basicobject.h"
#include "class.h"
#include "ruby++/rppstring.h"

RPP::Class 
cRPP_BasicObject;

extern "C" VALUE
cRPP_BasicObject_classname(VALUE v_self)
{
  track1("%s::classname", v_self);
  const RPP::RPPObject<RPP::BasicObject> self = v_self;
  return RPP::String(self->classname());
}

static RPP::Class
init_basicobject(RPP::Module mRPP)
{
  cRPP_BasicObject = mRPP.define_class("BasicObject", rb_cObject);
  trace1("cRPP_BasicObject_classname = %ld", (unsigned long)cRPP_BasicObject_classname);
  cRPP_BasicObject.define_method("classname", cRPP_BasicObject_classname)
		   ;
  return cRPP_BasicObject;
}

void Init_librpprpp()
{
  const RPP::Module mRPP("RPP");
  const RPP::Class cBasicObject = init_basicobject(mRPP);
  const RPP::Class cObject = init_object(mRPP, cBasicObject);
  const RPP::Class cModule = init_module(mRPP, cObject);
  init_class(mRPP, cModule);
}

//===============================================================

// example used by module_spec
extern "C" VALUE
RPP_cBasicObject_classname(VALUE v_self)
{
  RPP::Object self = v_self;
  return RPP::String(self.classname());
}

// examples to get the mangle system for the 6 possible methods:
VALUE RPP_test_method(VALUE) { return Qnil; }
VALUE RPP_test_method(VALUE, VALUE) { return Qnil; }
VALUE RPP_test_method(VALUE, VALUE, VALUE) { return Qnil; }
VALUE RPP_test_method(VALUE, VALUE, VALUE, VALUE) { return Qnil; }
VALUE RPP_test_method(VALUE, VALUE, VALUE, VALUE, VALUE) { return Qnil; }

namespace NSX {
  namespace Y {
    VALUE RPP_test_method(int, VALUE *, VALUE) { return Qnil; }
  }
}

/* OBJDUMP:
000000000000407d g    DF .text	000000000000000f  Base        _Z15RPP_test_methodm
000000000000408c g    DF .text	0000000000000013  Base        _Z15RPP_test_methodmm
000000000000409f g    DF .text	0000000000000017  Base        _Z15RPP_test_methodmmm
00000000000040b6 g    DF .text	000000000000001b  Base        _Z15RPP_test_methodmmmm
00000000000040d1 g    DF .text	000000000000001f  Base        _Z15RPP_test_methodmmmmm
00000000000040f0 g    DF .text	0000000000000016  Base        _ZN3NSXN1Y15RPP_test_methodiPmm

'15' is just the length of RPP_test_method.
However on some platform VALUE is not unsigned long and the result may differ.
Or maybe it differs on 32 bits vs 64 bits.
And this is Itanium ABI only (so at least g++).
*/

