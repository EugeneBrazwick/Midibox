
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

//#define TRACE

#pragma implementation
#include <ruby.h>
#include <QtWidgets/QMainWindow>
#include "application.h"
#include "api_utils.h"
#include "object.h"

namespace R_Qt {

/* TRAGICALLY, all QWidgets need a QWidget for a parent.
 *
 * We have:  QMainWindow::QMainWindow(QWidget *parent = 0);
 * but also: QMainWindow::setParent(QObject *parent);
 *
 * Also the allocator cannot be given any arguments. 
 * So time to pray...
 */
static VALUE
cMainWindow_alloc(VALUE cMainWindow)
{
  trace("cMainWindow_alloc");
  QMainWindow * const mw = new QMainWindow;
  trace1("cMainWindow_alloc -> qptr %p", mw);
  return cObjectWrap(cMainWindow, mw);
}

void 
init_mainwindow(VALUE mQt, VALUE cWidget)
{
  trace2("init_mainwindow, mQt=%p, cWidget=%p", (void *)mQt, (void *)cWidget);
  const VALUE cMainWindow = rb_define_class_under(mQt, "MainWindow", cWidget);
  trace("HERE");
  rb_define_alloc_func(cMainWindow, cMainWindow_alloc);
  trace("init_mainwindow OK");
}

} // namespace R_Qt 
