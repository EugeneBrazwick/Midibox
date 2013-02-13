#if !defined(_RUBYPP_DATA_H_)
#define _RUBYPP_DATA_H_

#include "ruby++.h"

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
public:
  DataObject<T>(VALUE v): inherited(v)
    {
      Data_Get_Struct(v, T, Wrapped);
      if (!Wrapped) rb_raise(rb_eTypeError, "attempt to access a zombie");
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
