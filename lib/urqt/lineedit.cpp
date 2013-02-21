
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

#include <QtWidgets/QLineEdit>
#include "application.h"
#include "ruby++/rppstring.h"
#include "ruby++/bool.h"

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
  const RPP::QObject<QLineEdit> self = v_self;
  self.check_frozen();
  self->setText(RPP::String(v_text).to_s());
  return v_text;
}

static VALUE
cLineEdit_text_get(VALUE v_self)
{
  const RPP::QObject<QLineEdit> self = v_self;
  return qString2v(self->text());
}

static VALUE
cLineEdit_readonly_p(VALUE v_self)
{
  const RPP::QObject<QLineEdit> self = v_self;
  return RPP::Bool(self->isReadOnly());
}

void
init_lineedit(RPP::Module qt, RPP::Class widget)
{
  trace1("init_lineedit, define R::Qt::Widget, mQt=%p", &qt);
  const RPP::Class cLineEdit = qt.define_class("LineEdit", widget);
  cLineEdit.define_alloc_func(cLineEdit_alloc)
	   .define_method("text=", cLineEdit_text_set)
	   .define_method("text_get", cLineEdit_text_get)
	   .define_method("readonly?", cLineEdit_readonly_p)
	   .define_method("readOnly?", cLineEdit_readonly_p)
	   .define_method("isReadOnly", cLineEdit_readonly_p)
	   ;
} // init_lineedit
} // namespace R_Qt
