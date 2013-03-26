#if !defined(_URQT_SIZE_H_)
#define _URQT_SIZE_H_

#include <QtCore/QSize>
#include <QtCore/QSizeF>
#include "ruby++/dataobject.h"

#pragma interface

namespace R_Qt {

extern RPP::Class cSize, cSizeF;

extern void cSize_free(QSize *sz);
extern void cSizeF_free(QSizeF *sz);

extern void init_size(RPP::Module mQt);

} // namespace R_Qt 

namespace RPP {

class QSize: public DataObject< ::QSize >
{
private:
  typedef DataObject< ::QSize > inherited;
private:
  void assignQSize(::QSize *sz)
    {
      setWrapped(sz);
      assign(Data_Wrap_Struct(R_Qt::cSize, 0, R_Qt::cSize_free, sz), VERYUNSAFE);
    }
public:
  QSize(VALUE v_o, E_SAFETY safe = SAFE): 
    inherited(v_o, R_Qt::cSize, safe) 
    {
      //trace("using VALUE");
    }
  QSize(::QSize *sz): 
    inherited(Qnil, R_Qt::cSize, UNSAFE) 
    { 
      //trace("using ::QSize");
      assignQSize(sz); 
    }
  QSize(const ::QSize &sz): QSize(new ::QSize(sz)) {}
  QSize(int argc, VALUE *argv);
}; // class RPP::QSize

class QSizeF: public DataObject< ::QSizeF >
{
private:
  typedef DataObject< ::QSizeF > inherited;
private:
  void assignQSizeF(::QSizeF *sz)
    {
      //trace("setWrapped");
      setWrapped(sz);
      //trace("assign + Data_Wrap_Struct");
      assign(Data_Wrap_Struct(R_Qt::cSizeF, 0, R_Qt::cSizeF_free, sz), VERYUNSAFE);
      //trace("assignQSizeF OK");
    }
public:
  QSizeF(VALUE v_o, E_SAFETY safe = SAFE): inherited(v_o, R_Qt::cSizeF, safe) {}
  QSizeF(::QSizeF *sz): 
    inherited(Qnil, R_Qt::cSizeF, UNSAFE) 
    { 
      //trace("using ::QSizeF");
      assignQSizeF(sz); 
    }
  QSizeF(const ::QSizeF &sz): QSizeF(new ::QSizeF(sz)) {}
  QSizeF(int argc, VALUE *argv);
}; // class RPP::QSizeF

} // namespace RPP

#define RPP_DECL_SIZE_READER(rpp_class, rpp_method, cpp_class, cpp_method) \
static VALUE \
rpp_class##_##rpp_method##_get(VALUE v_self) \
{ \
  return RPP::QSize(cpp_class(v_self)->cpp_method()); \
}

#define RPP_DECL_SIZE_WRITER(rpp_class, rpp_method, cpp_class, cpp_method) \
static VALUE \
rpp_class##_##rpp_method##_set(int argc, VALUE *argv, VALUE v_self) \
{ \
  const cpp_class self = v_self; \
  self.check_frozen(); \
  self->cpp_method(RPP::QSize(argc, argv)); \
  return Qnil; \
}

#define RPP_DECL_SIZE_ACCESSOR(rpp_class, rpp_method, cpp_class, cpp_method) \
  RPP_DECL_SIZE_READER(rpp_class, rpp_method, cpp_class, cpp_method) \
  RPP_DECL_SIZE_WRITER(rpp_class, rpp_method, cpp_class, cpp_method)

#define RPP_DECL_SIZE_ACCESSOR2(rpp_class, rpp_method, cpp_class, cpp_method_get, \
				cpp_method_set) \
  RPP_DECL_SIZE_READER(rpp_class, rpp_method, cpp_class, cpp_method_get) \
  RPP_DECL_SIZE_WRITER(rpp_class, rpp_method, cpp_class, cpp_method_set)

#define RPP_DECL_SIZEF_READER(rpp_class, rpp_method, cpp_class, cpp_method) \
static VALUE \
rpp_class##_##rpp_method##_get(VALUE v_self) \
{ \
  return RPP::QSize(cpp_class(v_self)->cpp_method()); \
}

#define RPP_DECL_SIZEF_WRITER(rpp_class, rpp_method, cpp_class, cpp_method) \
static VALUE \
rpp_class##_##rpp_method##_set(int argc, VALUE *argv, VALUE v_self) \
{ \
  const cpp_class self = v_self; \
  self.check_frozen(); \
  self->cpp_method(RPP::QSize(argc, argv)); \
  return Qnil; \
}

#define RPP_DECL_SIZEF_ACCESSOR(rpp_class, rpp_method, cpp_class, cpp_method) \
  RPP_DECL_SIZEF_READER(rpp_class, rpp_method, cpp_class, cpp_method) \
  RPP_DECL_SIZEF_WRITER(rpp_class, rpp_method, cpp_class, cpp_method)

#define RPP_DECL_SIZEF_ACCESSOR2(rpp_class, rpp_method, cpp_class, cpp_method_get, \
				cpp_method_set) \
  RPP_DECL_SIZEF_READER(rpp_class, rpp_method, cpp_class, cpp_method_get) \
  RPP_DECL_SIZEF_WRITER(rpp_class, rpp_method, cpp_class, cpp_method_set)

#endif // _URQT_SIZE_H_
