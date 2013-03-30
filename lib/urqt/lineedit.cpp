
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

#include <QtWidgets/QLineEdit>
#include "application.h"
#include "urqtCore/qtflags_and_enums.h"
#include "ruby++/rppstring.h"
#include "ruby++/bool.h"
#include "ruby++/array.h"
#include "ruby++/hash.h"

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
cLineEdit_isReadOnly(VALUE v_self)
{
  const RPP::QObject<QLineEdit> self = v_self;
  return RPP::Bool(self->isReadOnly());
}

static VALUE
cLineEdit_setReadOnly(VALUE v_self, VALUE v_bool)
{
  const RPP::QObject<QLineEdit> self = v_self;
  self->setReadOnly(RPP::Bool(v_bool));
  return v_bool;
}

static VALUE
cLineEdit_maxLength_get(VALUE v_self)
{
  const RPP::QObject<QLineEdit> self = v_self;
  return RPP::Fixnum(self->maxLength());
}

static VALUE
cLineEdit_maxLength_set(VALUE v_self, VALUE v_max)
{
  const RPP::QObject<QLineEdit> self = v_self;
  self->setMaxLength(RPP::Fixnum(v_max));
  return v_max;
}

static VALUE
cLineEdit_alignment_get(VALUE v_self)
{
  const RPP::QObject<QLineEdit> self = v_self;
  const Qt::Alignment al = self->alignment();
  const RPP::Array r;
  if (al & Qt::AlignLeft) r << RPP::Symbol("left");
  if (al & Qt::AlignRight) r << RPP::Symbol("right");
  if (al & Qt::AlignHCenter) r << RPP::Symbol("center");
  if (al & Qt::AlignJustify) r << RPP::Symbol("justify");
  if (al & Qt::AlignTop) r << RPP::Symbol("top");
  if (al & Qt::AlignBottom) r << RPP::Symbol("bottom");
  if (al & Qt::AlignVCenter) r << RPP::Symbol("vcenter");
  if (al & Qt::AlignAbsolute) r << RPP::Symbol("absolute");
  return r;
}

static VALUE
cLineEdit_alignment_set(int argc, VALUE *argv, VALUE v_self)
{
  const RPP::QObject<QLineEdit> self = v_self;
  const RPP::Array alsyms(argc, argv);
  self->setAlignment(alsyms2qtalignment(alsyms));
  return alsyms;
}

void
init_lineedit(RPP::Module qt, RPP::Class widget)
{
  trace1("init_lineedit, define R::Qt::Widget, mQt=%p", &qt);
  const RPP::Class cLineEdit = qt.define_class("LineEdit", widget);
  cLineEdit.define_alloc_func(cLineEdit_alloc)
	   .define_method("text=", cLineEdit_text_set)
	   .define_method("text_get", cLineEdit_text_get)
	   .define_method("readOnly=", cLineEdit_setReadOnly)
	   .define_method("readOnly_get", cLineEdit_isReadOnly)
	   .define_method("maxLength=", cLineEdit_maxLength_set)
	   .define_method("maxLength_get", cLineEdit_maxLength_get)
	   .define_method("alignment=", cLineEdit_alignment_set)
	   .define_method("alignment_get", cLineEdit_alignment_get)
	   ;
} // init_lineedit
} // namespace R_Qt
