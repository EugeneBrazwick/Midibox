
#pragma implementation
#include "api_utils.h"
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
