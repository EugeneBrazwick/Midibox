
#include "ruby++/ruby++.h"
#include <QtCore/qnamespace.h>
#pragma interface

namespace R_Qt {

extern void init_time_model(RPP::Module qt, RPP::Class cObject);
extern Qt::TimerType sym2timertype(VALUE v_sym);

} // namespace R_Qt
