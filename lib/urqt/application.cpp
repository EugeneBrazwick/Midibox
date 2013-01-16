
// This document adheres to the GNU coding standard
// Copyright (c) 2012-2013 Eugene Brazwick

// Comment the following out to remove the DEBUG tags:
//#define TRACE

/** :rdoc:

application.cpp

This file contains the QApplication wrapper.
Also it contains the libraries initialization method that defines all other classes.
*/
#pragma implementation
#include <QtWidgets/QApplication>
#include <ruby.h>
#include <errno.h>
#include <assert.h>
#include "application.h"
#include "api_utils.h"
#include "object.h"

namespace R_Qt {

//static VALUE cApplication = Qnil;

static int _argc = 0;
static char **_argv = 0;

static void 
cApplication_free(QApplication * /*app*/)
{
  // normally an app runs once. So this is for debugging/speccing only
  if (_argv)
    {
      char **p = _argv;
      for (int i = 0; i <= _argc; i++, p++)
	{
	  trace2("free argv[%d] '%s'", i, *p);
	  free((void *)*p);
	}
      trace1("free argv ptr %p", _argv);
      free((void *)_argv);
      _argv = 0;
    }
}

/* The only sensible way to get argv seems to be converting ARGV.
 * But we must make sure ruby can't free the strings.
 *
 * THOSE STATICS ARE KILLING...
 * Why? because if we start 2 apps in the same binary
 * the second will kill the argv of the first, but that's
 * also his own!!
 */
static VALUE
cApplication_alloc(VALUE cApplication)
{
  trace2("cApplication_alloc, _argc=%d, _argv=%p", _argc, _argv);
  const VALUE vARGV = to_ary(rb_get_argv()); // rb_const_get(rb_mKernel, rb_intern("ARGV"));
  //VALUE vARGV0 = rb_argv0; // -- expect 'ruby' here! unless 'chmod +x' is used
  VALUE vARGV0 = rb_gv_get("$0");
  track2("vARGV=%s, vARGV0=%s", vARGV, vARGV0);
  const int c = 1 + RARRAY_LEN(vARGV);
  char **v = (char **)malloc(c * sizeof(char *)); 
  if (!v) rb_syserr_fail(errno, strerror(errno));
  trace1("allocated argv->%p", v);
  v[0] = strdup(StringValueCStr(vARGV0));
  if (!v[0]) rb_syserr_fail(errno, strerror(errno));
  VALUE *p = RARRAY_PTR(vARGV);
  trace1("argc = %d", c);
  // Note that _argc is 1 bigger than ARGV.length !!
  for (int i = 1; i < _argc; i++, p++)
    {
      if (!(v[i] = strdup(StringValueCStr(*p))))
	rb_syserr_fail(errno, strerror(errno));
    }
  _argc = c;
  _argv = v;
  traqt("new QApplication");
  QApplication * const app = new QApplication(_argc, _argv);
  trace1("cApplication_alloc -> qptr %p", app);
  return Data_Wrap_Struct(cApplication, cObject_mark, cApplication_free, app);
}

/** call-seq: new()
 */
static VALUE
cApplication_initialize(VALUE v_self)
{
  trace("cApplication_initialize");
  rb_call_super(0, 0);
  rb_iv_set(v_self, "@toplevel_widgets", rb_ary_new());
  rb_iv_set(v_self, "@quit", Qfalse);
  rb_gv_set("$app", v_self);
  return Qnil;
}

static VALUE
cApplication_exec(VALUE v_self)
{
  // Qt ignores quit if called before 'exec()' is started.
  // That is stupid
  const VALUE v_quit = rb_iv_get(v_self, "@quit");
  //  const int quit = RTEST(v_quit) ? NUM2INT(v_quit) : 0;
  if (RTEST(v_quit))
    return v_quit; 
  rb_iv_set(v_self, "@quit", Qnil);
  // should be == qApp anyway
  RQTDECLSELF(QApplication);
  trace("QApplication::exec()");
  traqt1("%s::exec", QTCLASS(self));
  return INT2NUM(self->exec());
}

static VALUE
cApplication_quit(VALUE v_self)
{
  RQTDECLSELF(QApplication);
  trace("QApplication::quit()");
  rb_iv_set(v_self, "@quit", INT2NUM(0));
  traqt1("%s::quit", QTCLASS(self));
  self->quit();
  return v_self;
}

static VALUE
cApplication_quit_p(VALUE v_self)
{
  RQTDECLSELF(QApplication);
  return rb_iv_get(v_self, "@quit");
}

static VALUE
cApplication_exit(VALUE v_self, VALUE v_exitcode)
{
  RQTDECLSELF(QApplication);
  track1("QApplication::exit(%s)", v_exitcode);
  rb_iv_set(v_self, "@quit", v_exitcode);
  traqt1("%s::exit", QTCLASS(self));
  self->exit(NUM2INT(v_exitcode));
  return v_self;
}

void
init_application(VALUE mQt, VALUE cControl)
{
  trace("init_application");
  /** :rdoc:
   * class Application
   *
   * Stub around QApplication.
   * Frees the application when going out of scope
   */
  const VALUE cApplication = rb_define_class_under(mQt, "Application", cControl);
  rb_define_alloc_func(cApplication, cApplication_alloc);
  rb_define_method(cApplication, "initialize", 
		   RUBY_METHOD_FUNC(cApplication_initialize), 0);
  // actually in core(!):
  rb_define_method(cApplication, "exec", RUBY_METHOD_FUNC(cApplication_exec), 0);
  // actually in core(!):
  rb_define_method(cApplication, "quit", RUBY_METHOD_FUNC(cApplication_quit), 0);
  rb_define_method(cApplication, "exit", RUBY_METHOD_FUNC(cApplication_exit), 1);
  rb_define_method(cApplication, "quit?", RUBY_METHOD_FUNC(cApplication_quit_p), 0);
}

static VALUE
init_control(VALUE mQt, VALUE cObject)
{
  trace("init_control");
  const VALUE cControl = rb_define_class_under(mQt, "Control", cObject);
  return cControl;
}

} // namespace R_Qt 

using namespace R_Qt;

#define RQT_APP_SETUP_CONTROL(t, qt) const VALUE c##qt = init_##t(mQt, cControl)
#define RQT_APP_SETUP_CONTROL0(t) init_##t(mQt, cControl)
#define RQT_APP_SETUP_GRAPHICSITEM(t) init_##t(mQt, cGraphicsItem)
#define RQT_APP_SETUP_WIDGET(t) init_##t(mQt, cWidget)

extern "C" void
Init_liburqt()
{
  trace("Init_liburqt");
  Init_liburqtCore();
  const VALUE cControl = init_control(mQt, cObject);
  RQT_APP_SETUP_ALL
  //  rb_define_method(cApplication, "initialize", RUBY_METHOD_FUNC(cApplication_initialize), 0);
}

