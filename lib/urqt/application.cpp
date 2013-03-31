
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
#include "urqtCore/core_app.h"
#include "ruby++/numeric.h"

namespace R_Qt {

//static VALUE cApplication = Qnil;

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
  int argc;
  char **argv;
  getArgCV(argc, argv);
  QApplication * const app = new QApplication(argc, argv);
  trace1("cApplication_alloc -> qptr %p", app);
  return Data_Wrap_Struct(cApplication, cObject_mark, cCoreApplication_free, app);
}

void
init_application(RPP::Module mQt, RPP::Class /*cControl*/)
{
  trace("init_application");
  /** :rdoc:
   * class Application
   *
   * Stub around QApplication.
   * Frees the application when going out of scope
   */
  const RPP::Class cApplication = mQt.define_class("Application", cCoreApplication);
  cApplication.define_alloc_func(cApplication_alloc)
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

