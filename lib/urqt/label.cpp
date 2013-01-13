
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

#include <QtWidgets/QLabel>
#include "application.h"

namespace R_Qt {

R_QT_DEF_ALLOCATOR(Label)

static inline VALUE 
assign(VALUE v_self, VALUE v_text, Qt::TextFormat format)
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
cLabel_text_assign(VALUE v_self, VALUE v_text)
{
  return assign(v_self, v_text, Qt::AutoText);
}

static VALUE
cLabel_rawtext_assign(VALUE v_self, VALUE v_text)
{
  return assign(v_self, v_text, Qt::PlainText);
}


static VALUE
cLabel_html_assign(VALUE v_self, VALUE v_text)
{
  return assign(v_self, v_text, Qt::RichText);
}


static VALUE
cLabel_get_text(VALUE v_self)
{
  RQTDECLSELF(QLabel);
  traqt1("%s::text", QTCLASS(self));
  return qString2v(self->text());
}

void
init_label(VALUE mQt, VALUE cWidget)
{
  trace1("init_widget, define R::Qt::Widget, mQt=%p", (void *)mQt);
  const VALUE cLabel = rb_define_class_under(mQt, "Label", cWidget);
  rb_define_alloc_func(cLabel, cLabel_alloc);
  rb_define_method(cLabel, "text=", RUBY_METHOD_FUNC(cLabel_text_assign), 1);
  rb_define_method(cLabel, "rawtext=", RUBY_METHOD_FUNC(cLabel_rawtext_assign), 1);
  rb_define_method(cLabel, "html=", RUBY_METHOD_FUNC(cLabel_html_assign), 1);
  rb_define_method(cLabel, "get_text", RUBY_METHOD_FUNC(cLabel_get_text), 0);
  rb_define_method(cLabel, "get_rawtext", RUBY_METHOD_FUNC(cLabel_get_text), 0);
  rb_define_method(cLabel, "get_html", RUBY_METHOD_FUNC(cLabel_get_text), 0);
} // init_label
} // namespace R_Qt {
