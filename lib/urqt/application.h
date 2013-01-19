
#include "api_utils.h"
#include "object.h"
#pragma interface

class QObject;

namespace R_Qt {

#define RQT_APP_SETUP_CONTROL(t, qt) \
extern VALUE init_##t(VALUE mQt, VALUE cControl)
#define RQT_APP_SETUP_CONTROL0(t) \
extern void init_##t(VALUE mQt, VALUE cControl)
#define RQT_APP_SETUP_GRAPHICSITEM(t) \
extern void init_##t(VALUE mQt, VALUE cGraphicsItem)
#define RQT_APP_SETUP_WIDGET(t) \
extern void init_##t(VALUE mQt, VALUE cGraphicsItem)

#define RQT_APP_SETUP_ALL \
  RQT_APP_SETUP_CONTROL(graphicsitem, GraphicsItem); \
  RQT_APP_SETUP_CONTROL(widget, Widget); \
  RQT_APP_SETUP_CONTROL0(graphicsscene); \
  RQT_APP_SETUP_CONTROL0(application); \
  RQT_APP_SETUP_CONTROL0(layout); \
  RQT_APP_SETUP_GRAPHICSITEM(qtellipse); \
  RQT_APP_SETUP_WIDGET(label); \
  RQT_APP_SETUP_WIDGET(lineedit); \
  RQT_APP_SETUP_WIDGET(slider); \
  RQT_APP_SETUP_WIDGET(graphicsview); \
  RQT_APP_SETUP_WIDGET(mainwindow); \

RQT_APP_SETUP_ALL

#undef RQT_APP_SETUP_CONTROL
#undef RQT_APP_SETUP_CONTROL0
#undef RQT_APP_SETUP_GRAPHICSITEM
#undef RQT_APP_SETUP_WIDGET

extern void init_rvalue();
} // namespace R_Qt 

