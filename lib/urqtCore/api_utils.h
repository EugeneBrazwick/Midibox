#if !defined (_URQT_API_UTILS_H_) 
#define _URQT_API_UTILS_H_
#include <ruby.h>
#include <QtCore/QObject>
#include <QtCore/QVariant>
#include "rvalue.h"

#if defined(TRACE)
#define trace(arg) fprintf(stderr, arg "\n");
#define trace1(arg, a) fprintf(stderr, arg "\n", a);
#define trace2(arg, a, b) fprintf(stderr, arg "\n", a, b);
#define trace3(arg, a, b, c) fprintf(stderr, arg "\n", a, b, c);
#define trace4(arg, a, b, c, d) fprintf(stderr, arg "\n", a, b, c, d);
#define track1(arg, a) fprintf(stderr, arg "\n", INSPECT(a));
#define track2(arg, a, b) fprintf(stderr, arg "\n", INSPECT(a), INSPECT(b));
#define track3(arg, a, b, c) fprintf(stderr, arg "\n", INSPECT(a), INSPECT(b), INSPECT(c));
#define track4(arg, a, b, c, d) fprintf(stderr, arg "\n", INSPECT(a), INSPECT(b), \
					INSPECT(c), INSPECT(d));
#else
#define trace(arg)
#define trace1(arg, a)
#define trace2(arg, a, b)
#define trace3(arg, a, b, c)
#define trace4(arg, a, b, c, d)
#define track1(arg, a)
#define track2(arg, a, b)
#define track3(arg, a, b, c)
#define track4(arg, a, b, c, d)
#endif

#define INSPECT(x) RSTRING_PTR(rb_inspect(x))
#define TO_S(x) RSTRING_PTR(rb_any_to_s(x))
#define STRINGIFY_INTERNAL(t) #t
#define STRINGIFY(t) STRINGIFY_INTERNAL(t)
#define My_Data_Get_Struct(v, Type, ptr) \
  do \
    { \
      Data_Get_Struct(v, Type, ptr); \
      if (!ptr) rb_raise(rb_eTypeError, "attempt to access a zombie"); \
    } \
  while (false)

#define GET_STRUCT_NODECL(Type, var) My_Data_Get_Struct(v_##var, Type, var)
#define GET_STRUCT(Type, var) Type *var; GET_STRUCT_NODECL(Type, var)
#define GET_STRUCT_PTR(Type, var) Type *var; My_Data_Get_Struct(*v_##var, Type, var)

namespace R_Qt {

// Stores v inside its own q object and returns that object
// Just use GET_STRUCT to simply go from v_x to x
static inline QObject *
v2qt(VALUE v_q)
{
  track1("v2qt(%s)", v_q);
  GET_STRUCT(QObject, q);
  q->setProperty("R_Qt::rvalue", QVariant::fromValue(RValue(v_q)));
  return q;
}

// Returns ruby instance for q. If invalid returns Qnil
static inline VALUE
qt2v(QObject *q)
{
  if (!q) return Qnil;
  trace1("qt2v(%p)", q);
  const QVariant &rvalue = q->property("R_Qt::rvalue");
  if (!rvalue.isValid()) return Qnil;
  const RValue &rv = rvalue.value<RValue>();
  trace2("qt2v(%p) -> rv %p", q, &rv);
  trace2("qt2v(%p) -> VALUE = %p", q, (void *)rv.v());
  trace2("qt2v(%p) -> INSPECT -> %s", q, INSPECT(rv));
  return rv;
}

static inline VALUE 
to_ary(VALUE any)
{
  const VALUE v = rb_check_array_type(any);
  if (NIL_P(v)) rb_bug("Could not convert %s to an array", TO_S(any));
  return v;
}

static inline const char *qString2cstr(const QString &s)
{
  return s.toUtf8().data();
}

extern VALUE qString2v(const QString &s);
} // namespace R_Qt 

#endif // _URQT_API_UTILS_H_
