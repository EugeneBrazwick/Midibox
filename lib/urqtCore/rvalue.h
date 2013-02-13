#if !defined(_R_QT_RVALUE_H_)
#define _R_QT_RVALUE_H_
#include "ruby++/ruby++.h"
#include <iostream>
#include <QtCore/QMetaType>

#pragma interface

//   FAILS namespace R_Qt {

#define T_RVALUE RValue
#define T_RGCGUARDEDVALUE RGCGuardedValue

class RValue: public RPP::BasicObject 
{
private:
  typedef RPP::BasicObject inherited;
public:
  RValue(VALUE v): inherited(v) {}
  RValue(): inherited() {}
  RValue(const RValue &other): inherited(other) {}
  ~RValue() {}
  //  VALUE v() const { return V; }   use '*'
  std::istream &read_from(std::istream &i) { return i >> V; }
};

class RGCGuardedValue 
{
private:
  VALUE V;
private:
  void release() { if (!NIL_P(V)) rb_gc_unregister_address(&V); }
  void lock() { if (!NIL_P(V)) rb_gc_register_address(&V); }
public:
  RGCGuardedValue(VALUE v): V(v) { lock(); }
  RGCGuardedValue(): V(Qnil) {}
  RGCGuardedValue(const RGCGuardedValue &other): V(other.V) { lock(); }
  ~RGCGuardedValue() { release(); }
  //VALUE v() const { return V; }     use '*'
  std::istream &read_from(std::istream &i) { release(); i >> V; lock(); return i; }
  operator VALUE() const { return V; }
  VALUE operator*() const { return V; }
};

namespace R_Qt {
extern void init_rvalue();

// id of the R_Qt::RValue type.
extern int RVALUE_ID, RGCGUARDEDVALUE_ID;

} // namespace R_Qt

/* You cannot currently use this outside or between programs.
 * It could be changed into reading and writing yaml for instance
 */
extern std::ostream &operator<<(std::ostream &o, const RValue &v);
extern std::istream &operator>>(std::istream &i, RValue &v);

extern std::ostream &operator<<(std::ostream &o, const RGCGuardedValue &v);
extern std::istream &operator>>(std::istream &i, RGCGuardedValue &v);
/* Usage:
 *    QVariant v = RValue(vX); 
 *    if (v.canConvert<RValue>())  // and it can
 *	vX = v.value<RValue>();
 */
Q_DECLARE_METATYPE(T_RVALUE);

#endif // _R_QT_RVALUE_H_
