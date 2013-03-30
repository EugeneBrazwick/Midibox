
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

//#define TRACE

#pragma implementation
#include "font.h"
#include "widget.h"
#include "urqtCore/object.h"
#include "ruby++/dataobject.h"
#include "ruby++/numeric.h"
#include <QtWidgets/QWidget>

namespace R_Qt {

RPP::Class 
cFont;

void
cFont_free(QFont *font)
{
  delete font;
}

static void
reattach_font(RPP::QFont self)
{
  trace("reattach_font");
  const RPP::Object v_parent = self.iv("@parent");
  if (v_parent.isNil()) 
    {
      trace("@parent is nil!");
      return;
    }
  v_parent.call("font=", self);
  trace("reattach_font OK");
} // reattach_font

static VALUE
cFont_alloc(VALUE /*cFont*/)
{
  return RPP::QFont(new QFont);
}

static VALUE
cFont_pointSize_set(VALUE v_self, VALUE v_ptsz)
{
  const RPP::QFont self = v_self;
  self.check_frozen();
  RPP::Float ptsz = v_ptsz;
  track2("%s::pointSize := %s", self, ptsz);
  /* convolution
  if (ptsz.isFixnum())
    self->setPointSize(ptsz.to_i());
  else
  */
  self->setPointSizeF(ptsz);
  reattach_font(self);
  return v_ptsz;
}

static VALUE
cFont_pointSize_get(VALUE v_self)
{
  const RPP::QFont self = v_self;
  return RPP::Float(self->pointSizeF());
}

void 
init_font(RPP::Module mQt)
{
  cFont = mQt.define_class("Font", cNoQtControl);
  cFont.define_alloc_func(cFont_alloc)
  //       .define_private_method("initialize", cFont_initialize)
       .define_method("pointSize=", cFont_pointSize_set)
       .define_method("pointSize_get", cFont_pointSize_get)
       ;
}

} // namespace R_Qt
