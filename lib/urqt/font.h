#if !defined(_URQT_FONT_H_)
#define _URQT_FONT_H_

// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

#include <QtGui/QFont>
#include "api_utils.h"
#include "ruby++/ruby++.h"

#pragma interface

namespace R_Qt {

extern RPP::Class cFont;

extern void cFont_free(QFont *font);

static inline VALUE
cFontWrap(QFont *font)
{
  return Data_Wrap_Struct(cFont, 0, cFont_free, font);
}

extern void init_font(RPP::Module mQt);

} // namespace R_Qt 

namespace RPP {
class QFont: public DataObject< ::QFont >
{
private:
  typedef DataObject< ::QFont > inherited;
public:
  /* If Unsafe is passed then the result can be nil as well as a QFont.
     But exceptions are raised if it is neither.
     The caller MUST test for isNil()!
   */
  QFont(VALUE v_o, E_SAFETY safe = SAFE): inherited(v_o, R_Qt::cFont, safe) {}
  QFont(::QFont *font): 
    inherited(Data_Wrap_Struct(R_Qt::cFont, 0, R_Qt::cFont_free, font), font) 
    {
    }
  QFont(const ::QFont &font): QFont(new ::QFont(font)) {}
  void operator=(VALUE v) { V = v; }
}; // class RPP::QFont

} // namespace RPP 

#endif // _URQT_FONT_H_
