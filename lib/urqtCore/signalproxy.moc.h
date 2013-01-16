
#include <QtCore/QObject>
#include <QtCore/QVariant>
#include <ruby/ruby.h>
#include "rvalue.h"

#pragma interface

namespace R_Qt {

class QSignalProxy: public QObject
{
  Q_OBJECT
private:
  typedef QObject inherited;
  VALUE Block; // must be gc'ed !
private slots:
  // These are the brokers:
  void handle() const;
  void handle(QObject *) const;
public:
  QSignalProxy(QObject *parent, const char *signal, VALUE v_block);
};
} // namespace R_Qt 
