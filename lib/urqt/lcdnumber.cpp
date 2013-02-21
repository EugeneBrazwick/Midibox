
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

#include <QtWidgets/QLCDNumber>
#include "frame.h"
#include "ruby++/numeric.h"
#include "ruby++/hash.h"
#include "urqtCore/object.h"

namespace R_Qt {

static RPP::Class
cLCDNumber;

static VALUE
cLCDNumber_alloc(VALUE cLCDNumber)
{
  return RPP::QObject<QLCDNumber>(cLCDNumber, new QLCDNumber);
}

static VALUE
cLCDNumber_digitCount_set(VALUE v_self, VALUE v_dcount)
{
  const RPP::QObject<QLCDNumber> self = v_self;
  self.check_frozen();
  self->setDigitCount(RPP::Fixnum(v_dcount));
  return v_dcount;
}

static VALUE
cLCDNumber_digitCount_get(VALUE v_self)
{
  return RPP::Fixnum(RPP::QObject<QLCDNumber>(v_self)->digitCount());
}

static VALUE
cLCDNumber_segmentStyle_set(VALUE v_self, VALUE v_style)
{
  const RPP::QObject<QLCDNumber> self = v_self;
  self.check_frozen();
  RPP::Dictionary styles(cLCDNumber.cv("@@segmentstyles"), RPP::VERYUNSAFE);
  if (!styles.isHash())
    {
      styles = RPP::Dictionary();
      cLCDNumber.cv_set("@@segmentstyles", styles);
#define QTSTYLE_DO(sym, qtstyle) \
      styles[#sym] = RPP::Fixnum(QLCDNumber::qtstyle)
      QTSTYLE_DO(default, Filled); 
      QTSTYLE_DO(filled, Filled); 
      QTSTYLE_DO(outline, Outline); 
      QTSTYLE_DO(outlined, Outline); 
      QTSTYLE_DO(flat, Flat); 
    }
  self->setSegmentStyle(QLCDNumber::SegmentStyle(RPP::Fixnum(styles[v_style]).to_i()));
  return v_style;
}

static VALUE
cLCDNumber_segmentStyle_get(VALUE v_self)
{
  switch (RPP::QObject<QLCDNumber>(v_self)->segmentStyle())
    {
    case QLCDNumber::Filled: return RPP::Symbol("filled");
    case QLCDNumber::Outline: return RPP::Symbol("outline");
    case QLCDNumber::Flat: return RPP::Symbol("flat");
    }
  rb_raise(eReform, "unsupported segmentstyle %d", (int)RPP::QObject<QLCDNumber>(v_self)->segmentStyle());
}

/* NOTE: QLCDNumber has limited caps for characters. ':' is supported though as 
 * are all HEX characters A-F.
 */
static VALUE 
cLCDNumber_display(VALUE v_self, VALUE v_ifs)
{
  const RPP::QObject<QLCDNumber> self = v_self;
  self.check_frozen();
  switch (TYPE(v_ifs))
    {
    case T_FLOAT: self->display(RPP::Float(v_ifs).to_f()); break;
    case T_FIXNUM: self->display(RPP::Fixnum(v_ifs).to_i()); break;
    default: self->display(RPP::String(v_ifs).to_s()); break;
    }
  return v_ifs;
}

void
init_lcdnumber(RPP::Module qt, RPP::Class)
{
  trace1("init_label, define R::Qt::Widget, mQt=%p", &qt);
  cLCDNumber = qt.define_class("LCDNumber", cFrame);
  cLCDNumber.define_alloc_func(cLCDNumber_alloc)
	    .define_method("digitCount_get", cLCDNumber_digitCount_get)
	    .define_method("digitCount=", cLCDNumber_digitCount_set)
	    .define_method("segmentStyle_get", cLCDNumber_segmentStyle_get)
	    .define_method("segmentStyle=", cLCDNumber_segmentStyle_set)
	    .define_method("display", cLCDNumber_display)
	    ;
} // init_lcdnumber

} // namespace R_Qt 
