
#include "api_utils.h"
#include "object.h"
#pragma interface

class QObject;

namespace R_Qt {

extern VALUE init_graphicsitem(VALUE mQt, VALUE cControl);
extern VALUE init_widget(VALUE mQt, VALUE cControl);
extern void init_graphicsscene(VALUE mQt, VALUE cControl);
extern void init_qtellipse(VALUE mQt, VALUE cGraphicsItem);
extern void init_label(VALUE mQt, VALUE cWidget);
extern void init_graphicsview(VALUE mQt, VALUE cWidget);
extern void init_mainwindow(VALUE mQt, VALUE cWidget);
extern void init_rvalue();
} // namespace R_Qt 

