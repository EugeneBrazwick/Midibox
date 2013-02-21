
#include <QtWidgets/QPushButton>
#include "application.h"
#include "ruby++/rppstring.h"

namespace R_Qt {

R_QT_DEF_ALLOCATOR(PushButton)

static VALUE
cAbstractButton_text_set(VALUE v_self, VALUE v_text)
{
  RPP::QObject<QAbstractButton> self = v_self;
  self->setText(RPP::String(v_text).to_s());
  return v_text;
}

void
init_button(RPP::Module mQt, RPP::Class cWidget)
{
  const RPP::Class cAbstractButton = mQt.define_class("AbstractButton", cWidget);
  cAbstractButton.define_method("text=", cAbstractButton_text_set);
  const RPP::Class cPushButton = mQt.define_class("PushButton", cAbstractButton);
  cPushButton.define_alloc_func(cPushButton_alloc);
}

} // namespace R_Qt 
