
// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

#pragma implementation
#include "frame.h"
#include <QtWidgets/QFrame>

namespace R_Qt {

RPP::Class
cFrame;

void 
init_frame(RPP::Module qt, RPP::Class widget)
{
  cFrame = qt.define_class("Frame", widget);
}

} // namespace R_Qt

