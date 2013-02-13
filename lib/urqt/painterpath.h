#if !defined(_URQT_PAINTERPATH_H_)
#define _URQT_PAINTERPATH_H_

#include <ruby/ruby.h>
#include <QtGui/QPainterPath>
#include "api_utils.h"

#pragma interface

namespace R_Qt {

extern VALUE cPainterPath;

extern void cPainterPath_free(QPainterPath *path);

static inline VALUE
cPainterPathWrap(QPainterPath *path)
{
  return Data_Wrap_Struct(cPainterPath, 0, cPainterPath_free, path);
}

static inline VALUE
cPainterPathWrap(const QPainterPath &path)
{
  return Data_Wrap_Struct(cPainterPath, 0, cPainterPath_free, new QPainterPath(path));
}

static inline QPainterPath &
v2painterpath(VALUE v)
{
#if defined(DEBUG)
  if (!rb_obj_is_instance_of(v, cPainterPath))
    rb_raise(rb_eTypeError, "SERIOUS PROGRAMMING ERROR: very bad cast to QPainterPath");
#endif // DEBUG
  QPainterPath *r;
  Data_Get_Struct(v, QPainterPath, r);
  if (!r)
    rb_raise(rb_eTypeError, "Bad cast to QPainterPath");
  return *r;
};

extern void init_painterpath(VALUE mQt);

static inline void
GetQPainterPath_noDecl(VALUE v_q, QPainterPath *&q)
{
#if defined(DEBUG)
  if (!rb_obj_is_kind_of(v_q, cPainterPath))
    rb_raise(rb_eTypeError, "SERIOUS PROGRAMMING ERROR: very bad cast to QPainterPath");
#endif // DEBUG
  GET_STRUCT_NODECL(QPainterPath, q);
}
} // namespace R_Qt 

#define RQTDECLARE_PAINTERPATH(var) QPainterPath *var; GetQPainterPath_noDecl(v_##var, var)

#endif // _URQT_PAINTERPATH_H_
