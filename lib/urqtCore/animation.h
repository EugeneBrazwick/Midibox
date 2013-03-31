
#pragma interface
#include <QtCore/QAbstractAnimation>
#include "ruby++/module.h"
#include "ruby++/symbol.h"

namespace R_Qt {
extern void init_animation(RPP::Module mQt, RPP::Class cControl);
extern RPP::Symbol QAbstractAnimation_State2Symbol(QAbstractAnimation::State state);

} // namespace R_Qt
