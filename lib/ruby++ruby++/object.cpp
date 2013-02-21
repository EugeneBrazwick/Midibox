
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

#pragma implementation

#include "object.h"

RPP::Class 
init_object(RPP::Module mRPP, RPP::Class cBasicObject)
{
  const RPP::Class cObject = mRPP.define_class("Object", cBasicObject);
  return cObject;
}

