
#pragma implementation
#include "api_utils.h"
#include "rvalue.h"
#include <ruby/encoding.h>

namespace R_Qt {

RPP::Class
cObject, 
cControl, 
cNoQtControl;

VALUE 
qString2v(const QString &s)
{
  const char * const t = qString2cstr(s);
  const VALUE r = rb_str_new_cstr(t);
  static const int enc = rb_enc_find_index("UTF-8");
  rb_enc_associate_index(r, enc);
  return r;
}

VALUE 
qByteArray2v(const QByteArray &s)
{
  const char * const t = qByteArray2cstr(s);
  const VALUE r = rb_str_new_cstr(t);
  static const int enc = rb_enc_find_index("ASCII-8BIT");
  rb_enc_associate_index(r, enc);
  return r;
}

VALUE 
qString2v_nil(const QString &s)
{
  const char * const t = qString2cstr(s);
  if (!*t) return Qnil;
  const VALUE r = rb_str_new_cstr(t);
  static const int enc = rb_enc_find_index("UTF-8");
  rb_enc_associate_index(r, enc);
  return r;
}

QVariant v2qvar_unsafe(VALUE v)
{
  switch (TYPE(v))
    {
    case T_NIL: return QVariant();
    case T_FALSE: return QVariant(false);
    case T_TRUE: return QVariant(true);
    case T_FLOAT: return QVariant(NUM2DBL(v));
    case T_FIXNUM: return QVariant(NUM2INT(v));
    case T_STRING: return QVariant(v2QString(v));
    /* we could also do size/rect/point and line */
    default: 
      break;
    }
  return QVariant::fromValue(RValue(v));
}

VALUE qvar2v_unsafe(const QVariant &v)
{
  switch (v.type())
    {
    case QMetaType::UnknownType: return Qnil;
    case QMetaType::Bool: return v.toBool() ? Qtrue : Qfalse;
    case QMetaType::Double: return DBL2NUM(v.toDouble());
    case QMetaType::Int: return INT2NUM(v.toInt());
    case QMetaType::QString: return qString2v(v.toString());
    default: 
      break;
    }
  const RValue &var = v.value<RValue>();
  return VALUE(var);
}
QVariant v2qvar_safe(VALUE v)
{
  switch (TYPE(v))
    {
    case T_NIL: return QVariant();
    case T_FALSE: return QVariant(false);
    case T_TRUE: return QVariant(true);
    case T_FLOAT: return QVariant(NUM2DBL(v));
    case T_FIXNUM: return QVariant(NUM2INT(v));
    case T_STRING: return QVariant(v2QString(v));
    /* we could also do size/rect/point and line */
    default: 
      break;
    }
  return QVariant::fromValue(RGCGuardedValue(v));
}

VALUE qvar2v_safe(const QVariant &v)
{
  switch (v.type())
    {
    case QMetaType::UnknownType: return Qnil;
    case QMetaType::Bool: return v.toBool() ? Qtrue : Qfalse;
    case QMetaType::Double: return DBL2NUM(v.toDouble());
    case QMetaType::Int: return INT2NUM(v.toInt());
    case QMetaType::QString: return qString2v(v.toString());
    default: 
      break;
    }
  const RGCGuardedValue &var = v.value<RGCGuardedValue>();
  return VALUE(var);
}

} // namespace R_Qt 
