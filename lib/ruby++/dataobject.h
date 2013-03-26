#if !defined(_RUBYPP_DATA_H_)
#define _RUBYPP_DATA_H_

#include "ruby++/class.h"

namespace RPP {

// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

template<class T> class DataObject: public Object
{
private:
  typedef Object inherited;
  T *Wrapped;
protected:
  // Use this->wrapped() and this->setWrapped() in subclasses!! (C++ quirck)
  T *wrapped() const { return Wrapped; }
  T *setWrapped(T *w) { return Wrapped = w; } // sic
  DataObject<T>(VALUE v, T *wrapped): inherited(v), Wrapped(wrapped) {}
public:
  /* Note: if Unsafe is passed the result can be nil 
     In that case the guarded pointer will be 0 as well.
     But the constructor will raise if anything but nil or T* is present.
   */
  DataObject<T>(VALUE v, Class target, E_SAFETY safe = SAFE): 
    Wrapped(0)
    {
      assign(v, safe);
      if (safe == SAFE || safe == UNSAFE && !this->isNil())
	{
	  if (!is_kind_of(target))
	    rb_raise(rb_eTypeError, "very bad cast of %s to %s", inspect(), target.to_s());
	}
    }
  override void assign(VALUE v, E_SAFETY safe = SAFE)
    {
      inherited::assign(v, safe);
      if (safe == SAFE || safe == UNSAFE && !this->isNil())
	{
	  Data_Get_Struct(V, T, Wrapped);
	  if (!Wrapped)	  // THIS IS ALWAYS WRONG, otherwise it becomes a mess.
	    rb_raise(rb_eTypeError, "attempt to access a zombie");
	}
    }
  // Note that VALUE can no longer be accessed. But VALUE() will still work
  // Use value() and value_ref() if required
  T *operator->() const { return Wrapped; }
  T *operator &() const { return Wrapped; }
  const T &operator *() const { return *Wrapped; }
  T &operator *() { return *Wrapped; }
  operator T*() const { return Wrapped; }
  operator const T&() const { return *Wrapped; }
};

} // namespace RPP 

#endif // _RUBYPP_DATA_H_
