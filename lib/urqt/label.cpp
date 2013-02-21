
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

#include <QtWidgets/QLabel>
#include "application.h"
#include "frame.h"
#include "ruby++/rppstring.h"

namespace R_Qt {

R_QT_DEF_ALLOCATOR(Label)

static inline VALUE 
set(VALUE v_self, VALUE v_text, Qt::TextFormat format)
{
  const RPP::QObject<QLabel> self = v_self;
  self.check_frozen();
  self->setTextFormat(format);
  self->setText(RPP::String(v_text).to_s());
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
  const RPP::QObject<QLabel> self = v_self;
  return qString2v(self->text());
}

void
init_label(RPP::Module qt, RPP::Class)
{
  trace1("init_label, define R::Qt::Widget, mQt=%p", &qt);
  const RPP::Class cLabel = qt.define_class("Label", cFrame);
  cLabel.define_alloc_func(cLabel_alloc)
	.define_method("text=", cLabel_text_set)
	.define_method("rawtext=", cLabel_rawtext_set)
	.define_method("html=", cLabel_html_set)
	.define_method("text_get", cLabel_text_get)
	.define_method("rawtext_get", cLabel_text_get)
	.define_method("html_get", cLabel_text_get)
	;
} // init_label

} // namespace R_Qt
