
#pragma implementation
#include "api_utils.h"
#include <ruby/encoding.h>

namespace R_Qt {

RPP::Class
cObject, 
cControl, 
cNoQtControl;

#if defined(DEBUG)

VALUE prop2v(QObject *q, const char *id)
{
  //  traqt2("%s::property(%s)", QTCLASS(q), R_QT_INTERNAL_PROPERTY_PREFIX "rvalue");
  const QVariant &rvalue = q->property(id);
  //  traqt("QVariant::isValid");     
  if (!rvalue.isValid()) return Qnil;
  //traqt("QVariant::value<RValue>");
  const RValue &rv = rvalue.value<RValue>();
  trace2("qt2v(%p) -> rv %p", q, &rv);
  trace2("qt2v(%p) -> VALUE = %p", q, (void *)rv.v());
  trace2("qt2v(%p) -> INSPECT -> %s", q, INSPECT(rv)); 
  return rv; 
}

#endif // DEBUG

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
qString2v_nil(const QString &s)
{
  const char * const t = qString2cstr(s);
  if (!*t) return Qnil;
  const VALUE r = rb_str_new_cstr(t);
  static const int enc = rb_enc_find_index("UTF-8");
  rb_enc_associate_index(r, enc);
  return r;
}
} // namespace R_Qt 
