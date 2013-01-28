
#include <QtCore/QObject>
#include <QtCore/QVariant>
#include <ruby/ruby.h>
#include "rvalue.h"
#include "object.h"

#pragma interface

namespace R_Qt {

class QSignalProxy: public QObject
{
  Q_OBJECT
private:
  typedef QObject inherited;
  GCSafeValue Block;
private:
  void handle_i(VALUE v_ary) const;
  VALUE block() const { return Block; }
private slots:
  // These are the brokers:
  void handle() const;
  void handle(QObject *) const;
  void handle(bool) const;
public:
  QSignalProxy(QObject *parent, const char *signal, VALUE v_block);
};
} // namespace R_Qt 
