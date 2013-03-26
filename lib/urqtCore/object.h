#if !defined (_URQT_OBJECT_H_)
#define _URQT_OBJECT_H_

// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

#include "ruby++/ruby++.h" 
#include "api_utils.h" /* "rather unavoidable" */
#include <typeinfo>
#pragma interface

namespace R_Qt {
extern RPP::Module mQt, mR; 
extern RPP::Class eReform;
extern RPP::Class cSynthObject, cDynamicAttribute;
extern RPP::Class cReformError;
extern RPP::Class cModel;

extern void cObject_mark(QObject *object);

// cannot be overloaded!
extern void cObject_signal_impl(VALUE v_self, const char *method, VALUE v_args, 
			        VALUE v_block);

// INTERNAL USE, use RPP::QObject<QClass>(klass, object)
static inline VALUE 
cObjectWrap(VALUE klass, QObject *object)
{
  return Data_Wrap_Struct(klass, cObject_mark, 0, object);
}

// ANY T_DATA instance
static inline void
ZOMBIFY(VALUE v)
{
  DATA_PTR(v) = 0;
}

static inline bool
IS_ZOMBIFIED(VALUE v)
{
  return DATA_PTR(v) == 0;
}

/* This class behaves similar to VALUE except that the Garbage Collector will
automatically leave it alone.
*/
class GCSafeValue
{
private:
  VALUE V;
public:
  GCSafeValue(VALUE v): V(v) { rb_gc_register_address(&V); }
  ~GCSafeValue() { rb_gc_unregister_address(&V); }
  VALUE operator ->() const { return V; }
  VALUE operator *() const { return V; }
  operator VALUE() const { return V; }
};

static inline void 
cObject_free(QObject *object)
{
  delete object;
}

} // namespace R_Qt 

namespace RPP {
// T must be a ::QObject (sub)class
template <class T> class QObject: public DataObject<T>
{
private:
  typedef DataObject<T> inherited;
public:
  /* if Unsafe is used the result can be nil as well as T*.
     But exceptions are raised if it is neither.
     The caller MUST test using isNil() or test()
  */
  QObject<T>(VALUE v_o, RPP::E_SAFETY safe = RPP::SAFE): inherited(v_o, ::R_Qt::cObject, safe)
    {
      // note that isNil implies isZombified
      if (safe == RPP::SAFE || safe == RPP::UNSAFE && !this->isNil())
	{
	  // additional dynamic test
	  ::QObject *const o = this->wrapped();
	  if (!dynamic_cast<T *>(o))
		// that subclass is actually 'T', but how can I get a string??
	    rb_raise(rb_eTypeError, "Bad cast to %s", typeid(T).name());
	}
    } 
  // The following is the correct way of using cObjectWrap 
  QObject<T>(VALUE klass, T *object): inherited(R_Qt::cObjectWrap(klass, object), object) {}
  // The following is the correct way of using qt2v. 
  QObject<T>(T *object, E_SAFETY safe = SAFE): 
    inherited(R_Qt::qt2v(object), object)
    {
      if (safe == SAFE && this->isNil())
	rb_raise(R_Qt::cReformError, "attempt to access a zombie");
    }
  void zombify() const { DATA_PTR(this->V) = 0; }
  bool is_zombified() const { return !DATA_PTR(this->V); }
  bool isZombified() const { return !DATA_PTR(this->V); }
  void takeOwnership() const { RDATA(this->V)->dfree = (void (*)(void*))R_Qt::cObject_free; }
  const char *qtclass() const { return this->wrapped()->metaObject()->className(); }
}; // class RPP::QObject

} // namespace RPP 

extern "C" void Init_liburqtCore();

#endif // _URQT_OBJECT_H_
