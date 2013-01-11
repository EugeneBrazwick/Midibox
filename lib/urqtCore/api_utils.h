#if !defined (_URQT_API_UTILS_H_) 
#define _URQT_API_UTILS_H_
#include <QtCore/QObject>
#include <QtCore/QVariant>
// #include "ruby++/ruby++.h"
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

#if defined(TRACE_QT_API)
#define traqt(arg) fprintf(stderr, "TRAQT: " arg "\n");
#define traqt1(arg, a) fprintf(stderr, "TRAQT: " arg "\n", a);
#define traqt2(arg, a, b) fprintf(stderr, "TRAQT: " arg "\n", a, b);
#define traqt3(arg, a, b, c) fprintf(stderr, "TRAQT: " arg "\n", a, b, c);
#define traqt4(arg, a, b, c, d) fprintf(stderr, "TRAQT: " arg "\n", a, b, c, d);
#else // !TRACE_QT_API
#define traqt(arg)
#define traqt1(arg, a)
#define traqt2(arg, a, b)
#define traqt3(arg, a, b, c)
#define traqt4(arg, a, b, c, d)
#endif

#define INSPECT(x) RSTRING_PTR(rb_inspect(x))
#define TO_S(x) RSTRING_PTR(rb_any_to_s(x))
#define STRINGIFY_INTERNAL(t) #t
#define STRINGIFY(t) STRINGIFY_INTERNAL(t)
      /* Check_Type(v, T_DATA);  seems not required in My_Data_Get_Struct */
#define My_Data_Get_Struct(v, Type, ptr) \
  do \
    { \
      Data_Get_Struct(v, Type, ptr); \
      if (!ptr) rb_raise(rb_eTypeError, "attempt to access a zombie"); \
    } \
  while (false)

// IMPORTANT: Data_Get_Struct is TYPE UNSAFE!!!!!  And so are these:
#define GET_STRUCT_NODECL(Type, var) My_Data_Get_Struct(v_##var, Type, var)
#define GET_STRUCT(Type, var) Type *var; GET_STRUCT_NODECL(Type, var)
#define GET_STRUCT_PTR(Type, var) Type *var; My_Data_Get_Struct(*v_##var, Type, var)

static inline const char *
QTCLASS(const QObject *o)
{
  return o ? o->metaObject()->className() : "NULL";
}

static inline const char *
QTCLASS(const QObject &o)
{
  return o.metaObject()->className();
}

namespace R_Qt {

extern VALUE cObject;

template <typename T> static inline void
GetQObject_noDecl(VALUE v_o, T *&q)
{
#if defined(DEBUG)
  if (!rb_obj_is_kind_of(v_o, cObject))
    rb_raise(rb_eTypeError, "SERIOUS PROGRAMMING ERROR: very bad cast to QObject");
#endif // DEBUG
  GET_STRUCT(QObject, o);
  q = dynamic_cast<T *>(o);
  if (!q) rb_raise(rb_eTypeError, "Bad cast to %s", QTCLASS(o));
}

/* use this macro if not using self, and not using QObject either.
 This macro is typesafe in DEBUG mode only. Otherwise it is almost
 typesafe but someone might pass a T_DATA item that is not a QObject
 pointer.
 Also, T must inherit QObject, but this is checked at compile time
*/
#define RQTDECLARE(T, var) T *var; GetQObject_noDecl<T>(v_##var, var)

#if defined(DEBUG)
#define RQTDECLSELF(T) RQTDECLARE(T, self)
#else // !DEBUG
#define RQTDECLSELF(T) GET_STRUCT(T, self)
#endif // !DEBUG

#define R_QT_INTERNAL_PROPERTY_PREFIX "R_Qt::"

// Stores v inside its own q object and returns that object
// Just use GET_STRUCT to simply go from v_x to x
static inline QObject *
v2qt(VALUE v_q)
{
  track1("v2qt(%s)", v_q);
  GET_STRUCT(QObject, q);
  q->setProperty(R_QT_INTERNAL_PROPERTY_PREFIX "rvalue", 
		 QVariant::fromValue(RValue(v_q)));
  return q;
}

// Returns ruby instance for q. If invalid returns Qnil

#if defined(DEBUG)
extern VALUE qt2v(QObject *);
#else // !DEBUG
static inline VALUE
qt2v(QObject *q)
{
  if (!q) return Qnil;
  const QVariant &rvalue = q->property(R_QT_INTERNAL_PROPERTY_PREFIX "rvalue");
  if (!rvalue.isValid()) return Qnil;
  return rvalue.value<RValue>();
}
#endif // !DEBUG

static inline VALUE 
to_ary(VALUE any)
{
  const VALUE v = rb_check_array_type(any);
  if (NIL_P(v)) rb_bug("Could not convert %s to an array", TO_S(any));
  return v;
}

static inline VALUE 
to_hash(VALUE any)
{
  const VALUE v = rb_check_hash_type(any);
  if (NIL_P(v)) rb_bug("Could not convert %s to a hash", TO_S(any));
  return v;
}

static inline VALUE
p(bool x)
{
  return x ? Qtrue : Qfalse;
}

static inline const char *qString2cstr(const QString &s)
{
  return s.toUtf8().data();
}

// qString2v makes a new rb string and sets the encoding to utf-8
extern VALUE qString2v(const QString &s);

/*
inline RPP::String qString2rpp(const QString &s)
{
  return RPP::String(qString2cstr(s)).to_utf8();
}
*/

static inline VALUE
cstr2sym(const char *s) 
{
  return ID2SYM(rb_intern(s));
}

#define CSTR2SYM(s) cstr2sym(s)
// don't confuse the two!
#define RQT2SYM(s) cstr2sym(#s)

} // namespace R_Qt 

#define override virtual

/* COTCHAS:   klass must be WITHOUT prefix Q
 *	      you must be inside namespace R_Qt
 */
#define R_QT_DEF_ALLOCATOR(klass) \
  static VALUE \
  c##klass##_alloc(VALUE c##klass) \
  { \
    trace("c" #klass "_alloc"); \
    Q##klass * const q = new Q##klass; \
    traqt1("new Q" #klass " -> %p", q); \
    return cObjectWrap(c##klass, q); \
  }

#endif // _URQT_API_UTILS_H_
