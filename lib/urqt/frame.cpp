
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

//#define TRACE

#pragma implementation

#include "frame.h"
#include "ruby++/numeric.h"
#include "ruby++/hash.h"
#include <QtWidgets/QAbstractScrollArea>

namespace R_Qt {

RPP::Class
cFrame,
cAbstractScrollArea;

static VALUE
cFrame_alloc(VALUE cFrame)
{
  return RPP::QObject<QFrame>(cFrame, new QFrame);
}

static VALUE
cFrame_shadow_get(VALUE v_self)
{
  const int d = RPP::QObject<QFrame>(v_self)->frameShadow();
  switch (d)
    {
      case QFrame::Plain: return RPP::Symbol("plain");
      case QFrame::Raised: return RPP::Symbol("raised");
      case QFrame::Sunken: return RPP::Symbol("sunken");
    }
  rb_raise(rb_eNotImpError, "no support for frameShadow %d", d);
}

static VALUE
cFrame_shadow_set(VALUE v_self, VALUE v_sym)
{
  track2("%s.shadow=(%s)", v_self, v_sym);
  const RPP::QObject<QFrame> self = v_self;
  self.check_frozen();
  RPP::Dictionary dct(cFrame.cv("@@shadowStyles"), RPP::VERYUNSAFE);
  if (!dct.isHash())
    {
      cFrame.cv_set("@@shadowStyles", dct = RPP::Dictionary());
#define ENTRY_DO(sym, enumval) dct[#sym] = RPP::Fixnum(QFrame::enumval)
      ENTRY_DO(default, Plain); 
      ENTRY_DO(plain, Plain); 
      ENTRY_DO(sunken, Sunken); 
      ENTRY_DO(raised, Raised); 
#undef ENTRY_DO
    }
  self->setFrameShadow(QFrame::Shadow(RPP::Fixnum(dct[v_sym]).to_i()));
  return v_sym;
}

static VALUE
cFrame_shape_get(VALUE v_self)
{
  const int d = RPP::QObject<QFrame>(v_self)->frameShape();
  switch (d)
    {
      case QFrame::NoFrame: return RPP::Symbol("none");
      case QFrame::Box: return RPP::Symbol("box");
      case QFrame::Panel: return RPP::Symbol("panel");
      case QFrame::StyledPanel: return RPP::Symbol("styled_panel");
      case QFrame::HLine: return RPP::Symbol("hline");
      case QFrame::VLine: return RPP::Symbol("vline");
      case QFrame::WinPanel: return RPP::Symbol("winpanel");
    }
  rb_raise(rb_eNotImpError, "no support for frameShape %d", d);
}

static VALUE
cFrame_shape_set(VALUE v_self, VALUE v_sym)
{
  const RPP::QObject<QFrame> self = v_self;
  self.check_frozen();
  RPP::Dictionary dct(cFrame.cv("@@shapeStyles"), RPP::VERYUNSAFE);
  if (!dct.isHash())
    {
      cFrame.cv_set("@@shapeStyles", dct = RPP::Dictionary());
#define ENTRY_DO(sym, enumval) dct[#sym] = RPP::Fixnum(QFrame::enumval)
      ENTRY_DO(default, NoFrame); 
      ENTRY_DO(none, NoFrame); 
      ENTRY_DO(noFrame, NoFrame); 
      ENTRY_DO(box, Box); 
      ENTRY_DO(panel, Panel); 
      ENTRY_DO(styled_panel, StyledPanel); 
      ENTRY_DO(styledPanel, StyledPanel); 
      ENTRY_DO(hline, HLine); 
      ENTRY_DO(horline, HLine); 
      ENTRY_DO(hLine, HLine); 
      ENTRY_DO(vline, VLine); 
      ENTRY_DO(verline, VLine); 
      ENTRY_DO(vLine, VLine); 
      ENTRY_DO(win_panel, WinPanel); 
      ENTRY_DO(winPanel, WinPanel); 
#undef ENTRY_DO
    }
  self->setFrameShape(QFrame::Shape(RPP::Fixnum(dct[v_sym]).to_i()));
  return v_sym;
}

static VALUE
cFrame_lineWidth_set(VALUE v_self, VALUE v_lw)
{
  const RPP::QObject<QFrame> self = v_self;
  self.check_frozen();
  self->setLineWidth(RPP::Fixnum(v_lw));
  return v_lw;
}

static VALUE
cFrame_lineWidth_get(VALUE v_self)
{
  return RPP::Fixnum(RPP::QObject<QFrame>(v_self)->lineWidth());
}

static VALUE
cFrame_midLineWidth_set(VALUE v_self, VALUE v_lw)
{
  const RPP::QObject<QFrame> self = v_self;
  self.check_frozen();
  self->setMidLineWidth(RPP::Fixnum(v_lw));
  return v_lw;
}

static VALUE
cFrame_midLineWidth_get(VALUE v_self)
{
  return RPP::Fixnum(RPP::QObject<QFrame>(v_self)->midLineWidth());
}

static RPP::Dictionary
scrollPolicies()
{
  RPP::Dictionary dct(cAbstractScrollArea.cv("@@scrollPolicies"), RPP::VERYUNSAFE);
  if (!dct.isHash())
    {
      cFrame.cv_set("@@scrollPolicies", dct = RPP::Dictionary());
#define ENTRY_DO(sym, enumval) dct[#sym] = RPP::Fixnum(Qt::ScrollBar##enumval)
      ENTRY_DO(default, AsNeeded); 
      ENTRY_DO(as_needed, AsNeeded); 
      ENTRY_DO(asNeeded, AsNeeded); 
      ENTRY_DO(alwaysOff, AlwaysOff);
      ENTRY_DO(always_off, AlwaysOff);
      ENTRY_DO(alwaysOn, AlwaysOn);
      ENTRY_DO(always_on, AlwaysOn);
#undef ENTRY_DO
    }
  return dct;
}

static VALUE
scrollpol2val(Qt::ScrollBarPolicy pol)
{
  switch (pol)
    {
    case Qt::ScrollBarAsNeeded: return RPP::Symbol("as_needed");
    case Qt::ScrollBarAlwaysOff: return RPP::Symbol("always_off");
    case Qt::ScrollBarAlwaysOn: return RPP::Symbol("always_on");
    }
  rb_raise(rb_eNotImpError, "unknown Qt:ScrollBarPolicy %d", (int)pol);
}

static VALUE
cAbstractScrollArea_horizontalScrollBarPolicy_set(VALUE v_self, VALUE v_sym)
{
  const RPP::QObject<QAbstractScrollArea> self = v_self;
  self.check_frozen();
  const RPP::Dictionary dct = scrollPolicies();
  self->setHorizontalScrollBarPolicy(Qt::ScrollBarPolicy(RPP::Fixnum(dct[v_sym]).to_i()));
  return v_sym;
}

static VALUE
cAbstractScrollArea_horizontalScrollBarPolicy_get(VALUE v_self)
{
  return scrollpol2val(RPP::QObject<QAbstractScrollArea>(v_self)->horizontalScrollBarPolicy());
}

static VALUE
cAbstractScrollArea_verticalScrollBarPolicy_set(VALUE v_self, VALUE v_sym)
{
  const RPP::QObject<QAbstractScrollArea> self = v_self;
  self.check_frozen();
  const RPP::Dictionary dct = scrollPolicies();
  self->setHorizontalScrollBarPolicy(Qt::ScrollBarPolicy(RPP::Fixnum(dct[v_sym]).to_i()));
  return v_sym;
}

static VALUE
cAbstractScrollArea_verticalScrollBarPolicy_get(VALUE v_self)
{
  return scrollpol2val(RPP::QObject<QAbstractScrollArea>(v_self)->verticalScrollBarPolicy());
}

void 
init_frame(RPP::Module qt, RPP::Class widget)
{
  cFrame = qt.define_class("Frame", widget);
  cFrame.define_alloc_func(cFrame_alloc)
	.define_method("shadow_get", cFrame_shadow_get)
	.define_method("shadow=", cFrame_shadow_set)
	.define_method("shape_get", cFrame_shape_get)
	.define_method("shape=", cFrame_shape_set)
	.define_method("lineWidth_get", cFrame_lineWidth_get)
	.define_method("lineWidth=", cFrame_lineWidth_set)
	.define_method("midLineWidth_get", cFrame_midLineWidth_get)
	.define_method("midLineWidth=", cFrame_midLineWidth_set)
	;
  cAbstractScrollArea = qt.define_class("AbstractScrollArea", cFrame);
  cAbstractScrollArea.define_method("horizontalScrollBarPolicy=",
				    cAbstractScrollArea_horizontalScrollBarPolicy_set)
		     .define_method("horizontalScrollBarPolicy_get",
				    cAbstractScrollArea_horizontalScrollBarPolicy_get)
		     .define_method("verticalScrollBarPolicy=",
				    cAbstractScrollArea_verticalScrollBarPolicy_set)
		     .define_method("verticalScrollBarPolicy_get",
				    cAbstractScrollArea_verticalScrollBarPolicy_get)
		     ;
}

} // namespace R_Qt

