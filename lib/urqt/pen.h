
#include <ruby/ruby.h>
#include <QtGui/QPen>
#include "api_utils.h"
#pragma interface

namespace R_Qt {

extern VALUE cPen;

extern void init_pen(VALUE mQt);

static inline void
GetQPen_noDecl(VALUE v_q, QPen *&q)
{
#if defined(DEBUG)
  if (!rb_obj_is_kind_of(v_q, cPen))
    rb_raise(rb_eTypeError, "SERIOUS PROGRAMMING ERROR: very bad cast to QPen");
#endif // DEBUG
  GET_STRUCT_NODECL(QPen, q);
}

#define RQTDECLARE_PEN(var) QPen *var; GetQPen_noDecl(v_##var, var)
} // namespace R_Qt
