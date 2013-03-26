
#include "object.h"
#pragma interface

class QObject;

namespace R_Qt {

#define RQT_APP_SETUP_CONTROL(t, qt) \
extern VALUE init_##t(RPP::Module mQt, RPP::Class cControl)
#define RQT_APP_SETUP_CONTROL0(t) \
extern void init_##t(RPP::Module mQt, RPP::Class cControl)
#define RQT_APP_SETUP_GRAPHICSITEM(t) \
extern void init_##t(RPP::Module mQt, RPP::Class cGraphicsItem)
#define RQT_APP_SETUP_WIDGET(t) \
extern void init_##t(RPP::Module mQt, RPP::Class cGraphicsItem)

#define RQT_APP_SETUP_ALL \
  RQT_APP_SETUP_CONTROL(graphicsitem, GraphicsItem); \
  RQT_APP_SETUP_CONTROL(widget, Widget); \
  RQT_APP_SETUP_CONTROL0(graphicsscene); \
  RQT_APP_SETUP_CONTROL0(application); \
  RQT_APP_SETUP_CONTROL0(layout); \
  RQT_APP_SETUP_GRAPHICSITEM(qtellipse); \
  RQT_APP_SETUP_GRAPHICSITEM(rectangle); \
  RQT_APP_SETUP_GRAPHICSITEM(polygon); \
  RQT_APP_SETUP_GRAPHICSITEM(lineitem); \
  RQT_APP_SETUP_GRAPHICSITEM(pathitem); \
  RQT_APP_SETUP_WIDGET(frame); \
  RQT_APP_SETUP_WIDGET(abstractitemview); /* is a abstractscrollarea! */ \
  RQT_APP_SETUP_WIDGET(label); /* is a frame!*/ \
  RQT_APP_SETUP_WIDGET(lcdnumber); /* is a frame!*/ \
  RQT_APP_SETUP_WIDGET(graphicsview); /* is a frame */\
  RQT_APP_SETUP_WIDGET(button); \
  RQT_APP_SETUP_WIDGET(combobox); \
  RQT_APP_SETUP_WIDGET(lineedit); \
  RQT_APP_SETUP_WIDGET(slider); \
  RQT_APP_SETUP_WIDGET(mainwindow); \

RQT_APP_SETUP_ALL

#undef RQT_APP_SETUP_CONTROL
#undef RQT_APP_SETUP_CONTROL0
#undef RQT_APP_SETUP_GRAPHICSITEM
#undef RQT_APP_SETUP_WIDGET

extern void init_rvalue();
} // namespace R_Qt 
