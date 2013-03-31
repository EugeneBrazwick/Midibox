#if !defined(_URQTCORE_CORE_APP_H_)
#define _URQTCORE_CORE_APP_H_
#include "urqtCore/object.h"
#include "ruby++/class.h"
#include <QtCore/QCoreApplication>
#pragma interface

namespace R_Qt {

extern RPP::Class cCoreApplication;
extern void init_core_app(RPP::Module mQt, RPP::Class cControl);
extern void cCoreApplication_free(QCoreApplication *);
extern void getArgCV(int &argc, char **&argv);

} // namespace R_Qt 
#endif // _URQTCORE_CORE_APP_H_
