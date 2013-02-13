#if !defined(_URQT_POINT_H_)
#define _URQT_POINT_H_

#include <ruby/ruby.h>
#include <QtCore/QPoint>
#include <QtCore/QPointF>

#pragma interface

namespace R_Qt {

extern VALUE cPoint, cPointF;

extern void cPoint_free(QPoint *sz);
extern void cPointF_free(QPointF *sz);

static inline VALUE
cPointFWrap(QPointF *sz)
{
  return Data_Wrap_Struct(cPointF, 0, cPointF_free, sz);
}

static inline VALUE
cPointFWrap(const QPointF &sz)
{
  return Data_Wrap_Struct(cPointF, 0, cPointF_free, new QPointF(sz));
}

static inline VALUE
cPointWrap(QPoint *sz)
{
  return Data_Wrap_Struct(cPoint, 0, cPoint_free, sz);
}

static inline VALUE
cPointWrap(const QPoint &sz)
{
  return Data_Wrap_Struct(cPoint, 0, cPoint_free, new QPoint(sz));
}

static inline QPointF&
v2pt(VALUE v)
{
#if defined(DEBUG)
  if (!rb_obj_is_instance_of(v, cPointF))
    rb_raise(rb_eTypeError, "SERIOUS PROGRAMMING ERROR: very bad cast to QPointF");
#endif // DEBUG
  QPointF *r;
  Data_Get_Struct(v, QPointF, r);
  if (!r)
    rb_raise(rb_eTypeError, "Bad cast to QPointF");
  return *r;
};

static inline QPoint&
v2point(VALUE v)
{
#if defined(DEBUG)
  if (!rb_obj_is_instance_of(v, cPoint))
    rb_raise(rb_eTypeError, "SERIOUS PROGRAMMING ERROR: very bad cast to QPoint");
#endif // DEBUG
  QPoint *r;
  Data_Get_Struct(v, QPoint, r);
  if (!r)
    rb_raise(rb_eTypeError, "Bad cast to QPoint");
  return *r;
};

extern QPointF args2QPointF(int argc, VALUE *argv);
extern QPoint args2QPoint(int argc, VALUE *argv);
extern void init_point(VALUE mQt);

#define ARGS2QPOINT() args2QPoint(argc, argv)
#define ARGS2QPOINTF() args2QPointF(argc, argv)

} // namespace R_Qt 
#endif // _URQT_POINT_H_
