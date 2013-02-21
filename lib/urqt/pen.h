
#include "ruby++/ruby++.h"
#include <QtGui/QPen>
#include "api_utils.h"
#pragma interface

namespace R_Qt {

extern RPP::Class cPen;

extern void init_pen(RPP::Module mQt);

static inline void
GetQPen_noDecl(VALUE v_q, QPen *&q)
{
#if defined(DEBUG)
  if (!rb_obj_is_kind_of(v_q, cPen))
    rb_raise(rb_eTypeError, "SERIOUS PROGRAMMING ERROR: very bad cast to QPen");
#endif // DEBUG
  GET_STRUCT_NODECL(QPen, q);
}

#define RQTDECLARE_PEN(var) QPen *var; GetQPen_noDecl(v_##var, var)

static inline void
cPen_free(QPen *pen)
{
  delete pen;
}

} // namespace R_Qt

namespace RPP {

class QPen: public DataObject< ::QPen >	  // SPACES MUST!
{
private:
  typedef DataObject< ::QPen > inherited;
public:
  QPen(VALUE v_o, E_SAFETY safe = SAFE): inherited(v_o, R_Qt::cPen, safe) {}
  QPen(::QPen *pen): inherited(Data_Wrap_Struct(R_Qt::cPen, 0, R_Qt::cPen_free, pen), pen) {}
  QPen(const ::QPen &pen): QPen(new ::QPen(pen)) {}
  void operator=(VALUE v) { V = v; }
}; // class RPP::QPen

} // namespace RPP 
