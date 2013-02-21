
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

//#define TRACE

#pragma implementation

#include "module.h"
#include "ruby++/rppstring.h"
#include "ruby++/numeric.h"

extern "C" VALUE
cRPP_Module_alloc(VALUE cModule)
{
  trace("cRPP_Module_alloc");
  return RPP::RPPObject<RPP::Module>(cModule, new RPP::Module);
}

extern "C" VALUE
cRPP_Module_initialize(int argc, VALUE *argv, VALUE v_self)
{
  VALUE v_name;
  rb_scan_args(argc, argv, "1", &v_name);
  const RPP::String name = v_name;
  RPP::RPPObject<RPP::Module> self = v_self;
  *self = RPP::Module(name.to_s());
  return Qnil;
}

extern "C" VALUE
cRPP_Module_define_method(int argc, VALUE *argv, VALUE v_self)
{
  if (argc > 2) rb_raise(rb_eNotImpError, "define_method with args");
  VALUE v_methodname, v_cfunc, v_args;
  rb_scan_args(argc, argv, "2*", &v_methodname, &v_cfunc, &v_args);
  trace2("v_cfunc = %s, v_cfunc.class = %s", INSPECT(v_cfunc), rb_obj_classname(v_cfunc));
  const RPP::String methodname = v_methodname;
  const RPP::Fixnum ptr = v_cfunc;
  const RPP::RPPObject<RPP::Module> self = v_self;
  track2("%s.define_method(%s)", self, methodname);
  self->define_method(methodname, RPP::Arg0Method(ptr.to_l())); 
  return v_self;
}

RPP::Class 
init_module(RPP::Module mRPP, RPP::Class cObject)
{
  const RPP::Class cModule = mRPP.define_class("Module", cObject);
  cModule.define_alloc_func(cRPP_Module_alloc)
	 .define_private_method("initialize", cRPP_Module_initialize)
	 .define_method("define_method", cRPP_Module_define_method)
	  ;
  return cModule;
}

