
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

#include <QtWidgets/QLineEdit>
#include "application.h"

namespace R_Qt {

R_QT_DEF_ALLOCATOR(LineEdit)

/** :call-seq:
 *    text= string
 *
 * This emits 'textChanged(const QString &)', but the contents is NOT validated.
 * Also the edit is considered to be 'clean' again.
 *
 * There is a signal 'editingFinished()' but strangely it does not 
 * give you the resulting (validated) text like 'textEdited(const QString &)' does.
 * But that triggers for each stupid character change, and the result is
 * not validated.
 */
static VALUE 
cLineEdit_text_set(VALUE v_self, VALUE v_text)
{
  RQTDECLSELF(QLineEdit);
  rb_check_frozen(v_self);
  traqt1("%s::setText", QTCLASS(self));
  self->setText(StringValueCStr(v_text));
  return v_text;
}

static VALUE
cLineEdit_text_get(VALUE v_self)
{
  RQTDECLSELF(QLineEdit);
  traqt1("%s::text", QTCLASS(self));
  return qString2v(self->text());
}

static VALUE
cLineEdit_readonly_p(VALUE v_self)
{
  RQTDECLSELF(QLineEdit);
  traqt1("%s::isReadOnly", QTCLASS(self));
  return p(self->isReadOnly());
}

void
init_lineedit(VALUE mQt, VALUE cWidget)
{
  trace1("init_lineedit, define R::Qt::Widget, mQt=%p", (void *)mQt);
  const VALUE cLineEdit = rb_define_class_under(mQt, "LineEdit", cWidget);
  rb_define_alloc_func(cLineEdit, cLineEdit_alloc);
  rb_define_method(cLineEdit, "text=", RUBY_METHOD_FUNC(cLineEdit_text_set), 1);
  rb_define_method(cLineEdit, "text_get", RUBY_METHOD_FUNC(cLineEdit_text_get), 0);
  rb_define_method(cLineEdit, "readonly?", RUBY_METHOD_FUNC(cLineEdit_readonly_p), 0);
  rb_define_method(cLineEdit, "readOnly?", RUBY_METHOD_FUNC(cLineEdit_readonly_p), 0);
  rb_define_method(cLineEdit, "isReadOnly", RUBY_METHOD_FUNC(cLineEdit_readonly_p), 0);
} // init_lineedit
} // namespace R_Qt
