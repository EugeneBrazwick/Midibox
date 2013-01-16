
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

#include <QtWidgets/QLabel>
#include "application.h"

namespace R_Qt {

R_QT_DEF_ALLOCATOR(Label)

static inline VALUE 
set(VALUE v_self, VALUE v_text, Qt::TextFormat format)
{
  RQTDECLSELF(QLabel);
  rb_check_frozen(v_self);
  traqt1("%s::setTextFormat", QTCLASS(self));
  self->setTextFormat(format);
  traqt1("%s::setText", QTCLASS(self));
  self->setText(StringValueCStr(v_text));
  return v_text;
}

static VALUE
cLabel_text_set(VALUE v_self, VALUE v_text)
{
  return set(v_self, v_text, Qt::AutoText);
}

static VALUE
cLabel_rawtext_set(VALUE v_self, VALUE v_text)
{
  return set(v_self, v_text, Qt::PlainText);
}


static VALUE
cLabel_html_set(VALUE v_self, VALUE v_text)
{
  return set(v_self, v_text, Qt::RichText);
}


static VALUE
cLabel_text_get(VALUE v_self)
{
  RQTDECLSELF(QLabel);
  traqt1("%s::text", QTCLASS(self));
  return qString2v(self->text());
}

void
init_label(VALUE mQt, VALUE cWidget)
{
  trace1("init_label, define R::Qt::Widget, mQt=%p", (void *)mQt);
  const VALUE cLabel = rb_define_class_under(mQt, "Label", cWidget);
  rb_define_alloc_func(cLabel, cLabel_alloc);
  rb_define_method(cLabel, "text=", RUBY_METHOD_FUNC(cLabel_text_set), 1);
  rb_define_method(cLabel, "rawtext=", RUBY_METHOD_FUNC(cLabel_rawtext_set), 1);
  rb_define_method(cLabel, "html=", RUBY_METHOD_FUNC(cLabel_html_set), 1);
  rb_define_method(cLabel, "text_get", RUBY_METHOD_FUNC(cLabel_text_get), 0);
  rb_define_method(cLabel, "rawtext_get", RUBY_METHOD_FUNC(cLabel_text_get), 0);
  rb_define_method(cLabel, "html_get", RUBY_METHOD_FUNC(cLabel_text_get), 0);
} // init_label

} // namespace R_Qt
