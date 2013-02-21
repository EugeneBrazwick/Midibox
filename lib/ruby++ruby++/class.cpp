
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

//#define TRACE

#pragma implementation

#include "class.h"
#include "ruby++/rppstring.h"

extern "C" VALUE
cRPP_Class_alloc(VALUE cRPP_Class)
{
  trace("cRPP_Class_alloc");
  return RPP::RPPObject<RPP::Class>(cRPP_Class, new RPP::Class);
}

extern "C" VALUE
cRPP_Class_initialize(int argc, VALUE *argv, VALUE v_self)
{
  trace("cRPP_Class_initialize");
  VALUE v_name, v_superclass;
  rb_scan_args(argc, argv, "11", &v_name, &v_superclass);
  const RPP::String name = v_name;
  RPP::Class superclass = v_superclass;
  if (superclass.isNil()) superclass = rb_cObject;
  RPP::RPPObject<RPP::Class> self = v_self;
  trace("call rb_define_class");
  *self = RPP::Class(name.to_s(), superclass);
  trace("OK");
  return Qnil;
}

RPP::Class 
init_class(RPP::Module mRPP, RPP::Class cModule)
{
  const RPP::Class cClass = mRPP.define_class("Class", cModule);
  cClass.define_alloc_func(cRPP_Class_alloc)
	.define_private_method("initialize", cRPP_Class_initialize)
	;
  return cClass;
}

