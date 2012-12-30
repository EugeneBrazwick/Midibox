#if !defined(_R_QT_RVALUE_H_)
#define _R_QT_RVALUE_H_
#include <ruby.h>
#include <iostream>
#include <QtCore/QMetaType>

#pragma interface

//   FAILS namespace R_Qt {

#define T_RVALUE RValue

class RValue 
{
  private:
    VALUE V;
  public:
    RValue(VALUE v): V(v) {}
    RValue(): V(Qnil) {}
    RValue(const RValue &other): V(other.V) {}
    ~RValue() {}
    VALUE v() const { return V; }
    std::istream &read_from(std::istream &i) { return i >> V; }
    operator VALUE() const { return V; }
    VALUE operator*() const { return V; }
};

namespace R_Qt {
extern void init_rvalue();

// id of the R_Qt::RValue type.
extern int RVALUE_ID;

} // namespace R_Qt

/* You cannot currently use this outside or between programs.
 * It could be changed into reading and writing yaml for instance
 */
extern std::ostream &operator<<(std::ostream &o, const RValue &v);
extern std::istream &operator>>(std::istream &i, RValue &v);

/* Usage:
 *    QVariant v = RValue(vX); 
 *    if (v.canConvert<RValue>())  // and it can
 *	vX = v.value<RValue>();
 */
Q_DECLARE_METATYPE(T_RVALUE);

#endif // _R_QT_RVALUE_H_
