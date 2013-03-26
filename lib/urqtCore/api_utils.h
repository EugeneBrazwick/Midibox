#if !defined (_URQT_API_UTILS_H_) 
#define _URQT_API_UTILS_H_

// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

#include <QtCore/QObject>
#include <QtCore/QVariant>
#include "rvalue.h"
#include "ruby++/dataobject.h"

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

namespace R_Qt {

// handy for debugging:
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

extern RPP::Class cObject, cControl, cNoQtControl;

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
 This macro is almost typesafe in DEBUG mode only. Otherwise it is reasonable
 typesafe but someone might pass a T_DATA item that is not a QObject
 pointer.
 Also, T must inherit QObject, but this is checked at compile time

IMPORTANT: even in DEBUG mode, if a DATA was passed inside a cObject
instance, that is NOT a QObject, SEGV follows, and this can't ever
be detected, obviously.
An example would be the GraphicsItem classes.
*/
#define RQTDECLARE(T, var) T *var; GetQObject_noDecl<T>(v_##var, var)

#if defined(DEBUG)
#define RQTDECLSELF(T) RQTDECLARE(T, self)
#else // !DEBUG
#define RQTDECLSELF(T) GET_STRUCT(T, self)
#endif // !DEBUG

#define R_QT_INTERNAL_PROPERTY_PREFIX "R_Qt::"

// the ruby VALUE is stored in the following property of all wrapped QObjects:
#define R_QT_RVALUE_PROPERTYID R_QT_INTERNAL_PROPERTY_PREFIX "rvalue"
// the next name is used for dynamic values
#define R_QT_DYNVALUE_PROPERTYID R_QT_INTERNAL_PROPERTY_PREFIX "dynvalue"

static inline QVariant 
v2qvar(const VALUE &v)
{
  return QVariant::fromValue(RValue(v));
}

static inline VALUE
qvar2v(const QVariant &v)
{
  return v.isValid() ? VALUE(v.value<RValue>()) : Qnil;
}

// Stores v inside its own q object and returns that object. 
// AVOID!
// Just use GET_STRUCT/RQTDECL-macros to simply go from v_x to x
static inline QObject *
v2qt(VALUE v_q)
{
  track1("v2qt(%s)", v_q);
  GET_STRUCT(QObject, q);
  q->setProperty(R_QT_RVALUE_PROPERTYID, v2qvar(v_q));
  return q;
} // v2qt

// Returns ruby instance for q. If invalid returns Qnil

static inline VALUE
prop2v(const QObject *q, const char *id)
{
  return qvar2v(q->property(id));
}

// INTERNAL, use RPP::QObject<QClass>(q)
static inline VALUE
qt2v(const QObject *q)
{
  //trace2("qt2v(%s %p)", q ? QTCLASS(q) : "NULL", q);
  return q ? prop2v(q, R_QT_RVALUE_PROPERTYID) : Qnil;
} // qt2v

// INTERNAL or DEPRECATED. Just use RPP::Array constructor.
static inline VALUE 
to_ary(VALUE any)
{
  const VALUE v = rb_check_array_type(any);
  if (NIL_P(v)) rb_raise(rb_eTypeError, "Could not convert %s to an array", TO_CSTR(any));
  return v;
}

static inline VALUE 
to_hash(VALUE any)
{
  const VALUE v = rb_check_hash_type(any);
  if (NIL_P(v)) rb_raise(rb_eTypeError, "Could not convert %s to a hash", TO_CSTR(any));
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
// qString2v_nil is like qString2v but returns nil for ""
extern VALUE qString2v_nil(const QString &s);

// v2QString converts a ruby String to a QString.
static inline QString v2QString(VALUE v) { return QString(StringValueCStr(v)); }

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
#define R_QT_DEF_ALLOCATOR_BASE(klass, base) \
  static VALUE \
  c##klass##_alloc(VALUE c##klass) \
  { \
    trace("c" #klass "_alloc"); \
    Q##klass * const q = new Q##klass; \
    traqt1("new Q" #klass " -> %p", q); \
    return c##base##Wrap(c##klass, q); \
  }

// in case klass == base this can be used. For example for Color,Rect,Brush etc.
#define R_QT_DEF_ALLOCATOR_BASE1(base) \
  static VALUE \
  c##base##_alloc(VALUE /*c##base*/) \
  { \
    trace("c" #base "_alloc"); \
    Q##base * const q = new Q##base; \
    traqt1("new Q" #base " -> %p", q); \
    return c##base##Wrap(q); \
  }

#define R_QT_DEF_ALLOCATOR(klass) R_QT_DEF_ALLOCATOR_BASE(klass, Object)
#define R_QT_DEF_GRALLOCATOR(klass) R_QT_DEF_ALLOCATOR_BASE(klass, GraphicsItem)

#endif // _URQT_API_UTILS_H_
