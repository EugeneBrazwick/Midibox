
// Copyright (c) 2013 Eugene Brazwick

#pragma implementation
#include "painterpath.h"
#include "point.h"

namespace R_Qt {

VALUE
cPainterPath = Qnil;

void
cPainterPath_free(QPainterPath *pt)
{
  delete pt;
}

R_QT_DEF_ALLOCATOR_BASE1(PainterPath)

static VALUE
cPainterPath_moveTo(int argc, VALUE *argv, VALUE v_self)
{
  RQTDECLARE_PAINTERPATH(self);
  self->moveTo(ARGS2QPOINTF());
  return v_self;
}

static VALUE
cPainterPath_lineTo(int argc, VALUE *argv, VALUE v_self)
{
  RQTDECLARE_PAINTERPATH(self);
  self->lineTo(ARGS2QPOINTF());
  return v_self;
}

// CONTEXT: init_graphicsitem()
void
init_painterpath(VALUE mQt)
{
  cPainterPath = rb_define_class_under(mQt, "PainterPath", rb_cObject);
  rb_define_alloc_func(cPainterPath, cPainterPath_alloc);
  rb_define_method(cPainterPath, "moveTo", RUBY_METHOD_FUNC(cPainterPath_moveTo), -1);
  rb_define_method(cPainterPath, "lineTo", RUBY_METHOD_FUNC(cPainterPath_lineTo), -1);
}

} // namespace
