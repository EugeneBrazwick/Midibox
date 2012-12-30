
#pragma implementation
#include "api_utils.h"
#include <ruby/encoding.h>

namespace R_Qt {
VALUE 
qString2v(const QString &s)
{
  const VALUE r = rb_str_new_cstr(qString2cstr(s));
  static const int enc = rb_enc_find_index("UTF-8");
  rb_enc_associate_index(r, enc);
  return r;
}
} // namespace R_Qt 
