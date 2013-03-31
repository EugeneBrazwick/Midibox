
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

#pragma implementation
#include "core_app.h"
#include "object.h"
#include "ruby++/numeric.h"

namespace R_Qt {

RPP::Class 
cCoreApplication;

static int _argc = 0;
static char **_argv = 0;

void
getArgCV(int &argc, char **&argv)
{ 
  argc = 0;
  argv = 0;
  trace2("getArgCV, _argc=%d, _argv=%p", _argc, _argv);
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
  argc = _argc = c;
  argv = _argv = v;
}

static inline void
destroyArgCV()
{
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

void 
cCoreApplication_free(QCoreApplication *)
  // also used for cApplication!
{
  destroyArgCV();
  rb_gv_set("$app", Qnil);
  // Must NOT delete qApp. Because reform::app already does that.
}

static VALUE
cCoreApplication_alloc(VALUE cCoreApplication)
{
  int argc;
  char **argv;
  getArgCV(argc, argv);
  QCoreApplication * const app = new QCoreApplication(_argc, _argv);
  trace1("cCoreApplication_alloc -> qptr %p", app);
  return Data_Wrap_Struct(cCoreApplication, cObject_mark, cCoreApplication_free, app);
}

static VALUE
cCoreApplication_exec(VALUE v_self)
{
  // Qt ignores quit if called before 'exec()' is started.
  // That is stupid
  const RPP::QObject<QCoreApplication> self = v_self;
  const RPP::Object quit = self.iv("@quit");
  //  const int quit = RTEST(v_quit) ? NUM2INT(v_quit) : 0;
  if (quit.test()) return quit; 
  self.iv_set("@quit", Qnil);
  // should be == qApp anyway
  trace("QApplication::exec()");
  return RPP::Fixnum(self->exec());
}

static VALUE
cCoreApplication_quit(VALUE v_self)
{
  const RPP::QObject<QCoreApplication> self = v_self;
  trace("QApplication::quit()");
  self.iv_set("@quit", 0);
  self->quit();
  return self;
}

static VALUE
cCoreApplication_exit(VALUE v_self, VALUE v_exitcode)
{
  const RPP::QObject<QCoreApplication> self = v_self;
  track1("QApplication::exit(%s)", v_exitcode);
  self.iv_set("@quit", v_exitcode);
  self->exit(RPP::Fixnum(v_exitcode));
  return self;
}

void
init_core_app(RPP::Module mQt, RPP::Class cControl)
{
  cCoreApplication = mQt.define_class("CoreApplication", cControl);
  cCoreApplication.define_alloc_func(cCoreApplication_alloc)
		  .define_method("exec", cCoreApplication_exec)
		  .define_method("quit", cCoreApplication_quit)
		  .define_method("exit", cCoreApplication_exit)
		  ;
}

} // namespace R_Qt
