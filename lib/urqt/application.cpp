
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
#include "ruby++/numeric.h"

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
  trace1("v[0] := '%s'", v[0]);
  if (!v[0]) rb_syserr_fail(errno, strerror(errno));
  VALUE *p = RARRAY_PTR(vARGV);
  trace1("argc = %d", c);
  // Note that c is 1 bigger than ARGV.length !!
  for (int i = 1; i < c; i++, p++)
    {
      if (!(v[i] = strdup(StringValueCStr(*p))))
	rb_syserr_fail(errno, strerror(errno));
      trace2("v[%d] := '%s'", i, v[i]);
    }
  _argc = c;
  _argv = v;
  trace2("new QApplication, _argc=%d, _argv=%p", c, v);
  traqt("new QApplication");
  // CRASHES with chance 25%:
  QApplication * const app = new QApplication(_argc, _argv);
  trace1("cApplication_alloc -> qptr %p", app);
  return Data_Wrap_Struct(cApplication, cObject_mark, cApplication_free, app);
}

static VALUE
cApplication_exec(VALUE v_self)
{
  // Qt ignores quit if called before 'exec()' is started.
  // That is stupid
  const RPP::QObject<QApplication> self = v_self;
  const RPP::Object quit = self.iv("@quit");
  //  const int quit = RTEST(v_quit) ? NUM2INT(v_quit) : 0;
  if (quit.test()) return quit; 
  self.iv_set("@quit", Qnil);
  // should be == qApp anyway
  trace("QApplication::exec()");
  return RPP::Fixnum(self->exec());
}

static VALUE
cApplication_quit(VALUE v_self)
{
  const RPP::QObject<QApplication> self = v_self;
  trace("QApplication::quit()");
  self.iv_set("@quit", 0);
  self->quit();
  return self;
}

static VALUE
cApplication_exit(VALUE v_self, VALUE v_exitcode)
{
  const RPP::QObject<QApplication> self = v_self;
  track1("QApplication::exit(%s)", v_exitcode);
  self.iv_set("@quit", v_exitcode);
  self->exit(RPP::Fixnum(v_exitcode));
  return self;
}

void
init_application(RPP::Module mQt, RPP::Class cControl)
{
  trace("init_application");
  /** :rdoc:
   * class Application
   *
   * Stub around QApplication.
   * Frees the application when going out of scope
   */
  const RPP::Class cApplication = mQt.define_class("Application", cControl);
  cApplication.define_alloc_func(cApplication_alloc)
	      .define_method("exec", cApplication_exec)	 // actually part of QtCore !
	      .define_method("quit", cApplication_quit) // ""
	      .define_method("exit", cApplication_exit)
	      ;
}

static RPP::Class
init_control(RPP::Module mQt, RPP::Class cObject)
{
  trace("init_control");
  return mQt.define_class("Control", cObject);
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
  const RPP::Class cControl = init_control(mQt, cObject);
  RQT_APP_SETUP_ALL
  //  rb_define_method(cApplication, "initialize", RUBY_METHOD_FUNC(cApplication_initialize), 0);
}

