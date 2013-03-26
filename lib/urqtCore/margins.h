#if !defined(_URQTCORE_MARGINS_H_)
#define _URQTCORE_MARGINS_H_

// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

#include <QtCore/QMargins>
#include "ruby++/class.h"
#include "ruby++/dataobject.h"

#pragma interface

namespace R_Qt {

extern RPP::Class cMargins;

static inline void
cMargins_free(QMargins *m)
{
  delete m;
}

extern void init_margins(RPP::Module qt);

} // namespace R_Qt 

namespace RPP {

class QMargins: public DataObject< ::QMargins > 
{
private:
  typedef DataObject< ::QMargins > inherited;
  void assignQMargins(::QMargins *m)
    {
      setWrapped(m);
      assign(Data_Wrap_Struct(R_Qt::cMargins, 0, R_Qt::cMargins_free, m), VERYUNSAFE);
    }
public:
  QMargins(VALUE v_o, E_SAFETY safe = SAFE): inherited(v_o, R_Qt::cMargins, safe) {}
  QMargins(::QMargins *m): inherited(Qnil, UNSAFE) { assignQMargins(m); }
  QMargins(const ::QMargins &m): QMargins(new ::QMargins(m)) {}
  QMargins(int argc, VALUE *argv);
  //QMargins(int argc, VALUE *argv);
}; // class RPP::QMargins

} // namespace RPP 
#endif // _URQTCORE_MARGINS_H_
