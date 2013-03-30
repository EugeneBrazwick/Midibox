
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

//#define TRACE

#pragma implementation
#include "button.h"
#include <QtWidgets/QPushButton>
#include <QtWidgets/QToolButton>
#include "application.h"
#include "ruby++/rppstring.h"

namespace R_Qt {

RPP::Class 
cAbstractButton,
cPushButton,
cToolButton;

static VALUE
cPushButton_alloc(VALUE cPushButton)
{
  return RPP::QObject<QPushButton>(cPushButton, new QPushButton);
}

static VALUE
cToolButton_alloc(VALUE cToolButton)
{
  return RPP::QObject<QToolButton>(cToolButton, new QToolButton);
}

static VALUE
cAbstractButton_text_set(VALUE v_self, VALUE v_text)
{
  const RPP::QObject<QAbstractButton> self = v_self;
  self.check_frozen();
  self->setText(RPP::String(v_text).to_s());
  return v_text;
}

static VALUE
cAbstractButton_text_get(VALUE v_self)
{
  const RPP::QObject<QAbstractButton> self = v_self;
  return qString2v(self->text());
}

void
init_button(RPP::Module mQt, RPP::Class cWidget)
{
  trace("init_button");
  cAbstractButton = mQt.define_class("AbstractButton", cWidget);
  cAbstractButton.define_method("text=", cAbstractButton_text_set)
		 .define_method("text_get", cAbstractButton_text_get)
		 ;
  cPushButton = mQt.define_class("PushButton", cAbstractButton);
  cPushButton.define_alloc_func(cPushButton_alloc);
  trace("init ToolButton");
  cToolButton = mQt.define_class("ToolButton", cAbstractButton);
  cToolButton.define_alloc_func(cToolButton_alloc);
  trace("init_button OK");
}

} // namespace R_Qt 
