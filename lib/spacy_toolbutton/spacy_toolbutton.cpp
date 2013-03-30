
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

//#define TRACE

#include <QtWidgets/QToolButton>
#include "urqtCore/object.h"
#include "urqt/button.h"
#include "ruby++/rppstring.h"
#include "ruby++/regexp.h"

namespace R_Qt {

class QSpacyToolButton: public QToolButton
{
private:
  typedef QToolButton inherited;
public:
  QSpacyToolButton(QWidget *parent = 0): 
    inherited(parent)
    {
      trace("QSpacyToolButton.new");
      setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Preferred);
    }
  // this is nasty. Qt has no 'setSizeHint' so we must use C++ here.
  // Interestingly enough qtruby CAN override C++ methods inside ruby?
  // Or do they in fact subclass EVERY Qt class??
  override QSize sizeHint() const
    {
      trace("sizeHint()");
      QSize szh = inherited::sizeHint();
      szh.setHeight(szh.height() + 20);
      szh.setWidth(szh.width() > szh.height() ? szh.width() : szh.height());
      return szh;
    }
}; // class QSpacyToolButton

static VALUE
cSpacyToolButton_alloc(VALUE cSpacyToolButton)
{
  return RPP::QObject<QSpacyToolButton>(cSpacyToolButton, new QSpacyToolButton);
}

extern "C" void
Init_spacy_toolbutton()
{
  trace("Init_spacy_toolbutton");
  rb_require("reform/widgets/toolbutton");
  const RPP::Class cSpacyToolButton = mQt.define_class("SpacyToolButton", 
						       cToolButton);
  cSpacyToolButton.define_alloc_func(cSpacyToolButton_alloc);
  /* Note that __FILE__ is 
   *	    ~/Midibox/lib/spacy_toolbutton/spacy_toolbutton.cpp
   * but I now need
   *	    ~/Midibox/lib/reform/contrib/widgets/spacy_toolbutton.so
  const RPP::String fl = __FILE__;
  fl.call("sub!", RPP::Regexp("spacy_toolbutton"), RPP::String("reform/contrib/widgets"));
  fl.call("sub!", RPP::Regexp("\\.cpp$"), RPP::String(".so"));
  track1("mReform.createInstantiator(%s, cSpacyToolButton)", fl);

  NO STUPID. It uses basename anyway!!
   */
  mReform.call("createInstantiator", RPP::String(__FILE__), cSpacyToolButton);
}

} // namespace R_Qt 


