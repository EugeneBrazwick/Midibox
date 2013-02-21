#if !defined(_RPPRPP_BASICOBJECT_H_)
#define _RPPRPP_BASICOBJECT_H_

// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

/* We gonne Mock the Mockingbird.  http://en.wikipedia.org/wiki/To_Mock_a_Mockingbird

Note how urqtCore/object.cpp wraps around QObject using ruby++?
Well we are going to wrap around RPP::BasicObject in the same manner.
The methods used will be exported as 'extern "C"'.
This makes it possible of doing it again in ruby. For example to write a spec.
*/

#include "ruby++/dataobject.h"
#include <typeinfo>

#pragma interface

extern "C" void Init_librpprpp();

extern RPP::Class cRPP_BasicObject;

namespace RPP {
// T must be a RPP::BasicObject (sub)class
template <class T> class RPPObject: public DataObject<T>
{
private:
  typedef DataObject<T> inherited;
public:
  RPPObject<T>(VALUE v_o): inherited(v_o, cRPP_BasicObject)
    {
      RPP::BasicObject * const o = this->wrapped();
      if (!dynamic_cast<T *>(o))
	rb_raise(rb_eTypeError, "Bad cast to %s", typeid(T).name);
    }
  RPPObject<T>(VALUE klass, RPP::BasicObject *object): 
    inherited(Data_Wrap_Struct(klass, 0, 0, object), klass, RPP::VerySafe) 
    {
    }
}; // class RPP::RPPObject

} // namespace RPP

#endif // _RPPRPP_BASICOBJECT_H_
