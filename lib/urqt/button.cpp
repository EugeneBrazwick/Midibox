
#include <QtWidgets/QPushButton>
#include "application.h"

namespace R_Qt {

R_QT_DEF_ALLOCATOR(PushButton)

static VALUE
cAbstractButton_text_set(VALUE v_self, VALUE v_text)
{
  RQTDECLSELF(QAbstractButton);
  self->setText(StringValueCStr(v_text));
  return v_text;
}

void
init_button(VALUE mQt, VALUE cWidget)
{
  const VALUE cAbstractButton = rb_define_class_under(mQt, "AbstractButton", cWidget);
  rb_define_method(cAbstractButton, "text=", RUBY_METHOD_FUNC(cAbstractButton_text_set), 1);
  const VALUE cPushButton = rb_define_class_under(mQt, "PushButton", cAbstractButton);
  rb_define_alloc_func(cPushButton, cPushButton_alloc);
}

} // namespace R_Qt 
