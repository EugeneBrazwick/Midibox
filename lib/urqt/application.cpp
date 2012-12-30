
// This document adheres to the GNU coding standard
// Copyright (c) 2012-2013 Eugene Brazwick

// Comment the following out to remove the DEBUG tags:
#define TRACE

/** :rdoc:

application.cpp

This file contains the QApplication wrapper.
Also it contains the libraries initialization method that defines all other classes.
*/
#pragma implementation
#include <QtWidgets/QApplication>
#include <ruby.h>
#include <errno.h>
#include "application.h"
#include "api_utils.h"
#include "object.h"

namespace R_Qt {

//static VALUE cApplication = Qnil;

/* The only sensible way to get argv seems to be converting ARGV.
 * But we must make sure ruby can't free the strings.
 */
static VALUE
cApplication_alloc(VALUE cApplication)
{
  trace("cApplication_alloc");
  const VALUE vARGV = to_ary(rb_get_argv()); // rb_const_get(rb_mKernel, rb_intern("ARGV"));
  //VALUE vARGV0 = rb_argv0; // -- expect 'ruby' here! unless 'chmod +x' is used
  VALUE vARGV0 = rb_gv_get("$0");
  track2("vARGV=%s, vARGV0=%s", vARGV, vARGV0);
  static int _argc = 0;
  static char **_argv = 0;
  if (_argv)
    {
      char **p = _argv;
      for (int i = 0; i <= _argc; i++, p++)
	free((void *)*p);
      free((void *)_argv);
    }
  _argc = 1 + RARRAY_LEN(vARGV);
  _argv = (char **)malloc(_argc * sizeof(char *)); // never freed...
  if (!_argv) rb_syserr_fail(errno, strerror(errno));
  _argv[0] = strdup(StringValueCStr(vARGV0));
  if (!_argv[0]) rb_syserr_fail(errno, strerror(errno));
  VALUE *p = RARRAY_PTR(vARGV);
  trace1("argc = %d", _argc);
  // Note that _argc is 1 bigger than ARGV.length !!
  for (int i = 1; i < _argc; i++, p++)
    {
      if (!(_argv[i] = strdup(StringValueCStr(*p))))
	rb_syserr_fail(errno, strerror(errno));
    }
  QApplication * const app = new QApplication(_argc, _argv);
  trace1("cApplication_alloc -> qptr %p", app);
  return cObjectWrap(cApplication, app);
}

/** call-seq: new()
 */
static VALUE
cApplication_initialize(VALUE vSelf)
{
  trace("cApplication_initialize");
  rb_call_super(0, 0);
  rb_iv_set(vSelf, "@whenExiting", Qnil);
  //rb_gv_set("$app", vSelf); // Give it a reference... Just for show. Not used...
  return Qnil;
}

static VALUE
cApplication_exec(VALUE v_self)
{
  // should be == qApp anyway
  GET_STRUCT(QApplication, self);
  trace("QApplication::exec");
  return INT2NUM(self->exec());
}

static VALUE
init_control(VALUE mQt, VALUE cObject)
{
  const VALUE cControl = rb_define_class_under(mQt, "Control", cObject);
  return cControl;
}

static void
init_application(VALUE mQt, VALUE cControl)
{
  /** :rdoc:
   * class Application
   *
   * Stub around QApplication.
   * Frees the application when going out of scope
   */
  const VALUE cApplication = rb_define_class_under(mQt, "Application", cControl);
  rb_define_alloc_func(cApplication, cApplication_alloc);
  rb_define_method(cApplication, "initialize", RUBY_METHOD_FUNC(cApplication_initialize), 0);
  rb_define_method(cApplication, "exec", RUBY_METHOD_FUNC(cApplication_exec), 0);
}

static VALUE
init_widget(VALUE mQt, VALUE cControl)
{
  const VALUE cWidget = rb_define_class_under(mQt, "Widget", cControl);
  return cWidget;
}

} // namespace R_Qt 

using namespace R_Qt;

extern "C" void
Init_liburqt()
{
  const VALUE cControl = init_control(mQt, cObject);
  const VALUE cWidget = init_widget(mQt, cControl);
  init_application(mQt, cControl);
  init_mainwindow(mQt, cWidget);
  //  rb_define_method(cApplication, "initialize", RUBY_METHOD_FUNC(cApplication_initialize), 0);
}

