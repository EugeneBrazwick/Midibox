#if !defined(_URQT_SIZE_H_)
#define _URQT_SIZE_H_

#include <ruby/ruby.h>
#include <QtCore/QSize>
#include <QtCore/QSizeF>

#pragma interface

namespace R_Qt {

extern VALUE cSize, cSizeF;

extern void cSize_free(QSize *sz);
extern void cSizeF_free(QSizeF *sz);

static inline VALUE
cSizeFWrap(QSizeF *sz)
{
  return Data_Wrap_Struct(cSizeF, 0, cSizeF_free, sz);
}

static inline VALUE
cSizeFWrap(const QSizeF &sz)
{
  return Data_Wrap_Struct(cSizeF, 0, cSizeF_free, new QSizeF(sz));
}

static inline VALUE
cSizeWrap(QSize *sz)
{
  return Data_Wrap_Struct(cSize, 0, cSize_free, sz);
}

static inline VALUE
cSizeWrap(const QSize &sz)
{
  return Data_Wrap_Struct(cSize, 0, cSize_free, new QSize(sz));
}

static inline QSizeF&
v2sz(VALUE v)
{
#if defined(DEBUG)
  if (!rb_obj_is_instance_of(v, cSizeF))
    rb_raise(rb_eTypeError, "SERIOUS PROGRAMMING ERROR: very bad cast to QSizeF");
#endif // DEBUG
  QSizeF *r;
  Data_Get_Struct(v, QSizeF, r);
  if (!r)
    rb_raise(rb_eTypeError, "Bad cast to QSizeF");
  return *r;
};

static inline QSize&
v2size(VALUE v)
{
#if defined(DEBUG)
  if (!rb_obj_is_instance_of(v, cSize))
    rb_raise(rb_eTypeError, "SERIOUS PROGRAMMING ERROR: very bad cast to QSize");
#endif // DEBUG
  QSize *r;
  Data_Get_Struct(v, QSize, r);
  if (!r)
    rb_raise(rb_eTypeError, "Bad cast to QSize");
  return *r;
};

extern QSizeF args2QSizeF(int argc, VALUE *argv);
extern QSize args2QSize(int argc, VALUE *argv);
extern void init_size(VALUE mQt);

#define ARGS2QSIZE() args2QSize(argc, argv)
#define ARGS2QSIZEF() args2QSizeF(argc, argv)

} // namespace R_Qt 
#endif // _URQT_SIZE_H_
