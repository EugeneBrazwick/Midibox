#if !defined(_RPP_SCAN_H_)
#define _RPP_SCAN_H_

#include "ruby++/basicobject.h"

namespace RPP {

class Scan
{
private:
  const int OrgArgC;
  int ArgC;
  VALUE *ArgV;
  bool GotOpt;
  bool GotSplat; // to check for duplicate splat() calls.
public:
  Scan(int argc, VALUE *argv): 
    OrgArgC(argc), 
    ArgC(argc), 
    ArgV(argv), 
    GotOpt(false),
    GotSplat(false)
    {
    }
  Scan(int argc, VALUE *argv, BasicObject &v1): Scan(argc, argv)
    {
      arg(v1);
    }
  Scan(int argc, VALUE *argv, BasicObject &v1, BasicObject &v2): Scan(argc, argv, v1)
    {
      arg(v2);
    }
  Scan(int argc, VALUE *argv, BasicObject &v1, BasicObject &v2, BasicObject &v3): 
    Scan(argc, argv, v1, v2) 
    {
      arg(v3);
    }
  Scan(int argc, VALUE *argv, BasicObject &v1, BasicObject &v2, BasicObject &v3,
       BasicObject &v4): 
    Scan(argc, argv, v1, v2, v3) 
    {
      arg(v4);
    }
  ~Scan() { if (ArgC) rb_raise(rb_eArgError, "Scan: too many arguments (%d) given", OrgArgC); }
  Scan &arg(BasicObject &v1)
    {
      trace1("arg, ArgC=%d", ArgC);
      if (ArgC <= 0)
	rb_raise(rb_eArgError, "Scan: too few arguments (%d) given", OrgArgC);
      v1.assign(*ArgV, SAFE);
      ArgC--, ArgV++;
      return *this;
    }
  Scan &args(BasicObject &v1, BasicObject &v2) 
    { 
      arg(v1);
      return arg(v2);
    }
  Scan &args(BasicObject &v1, BasicObject &v2, BasicObject &v3)
    { 
      args(v1, v2);
      return arg(v3);
    }
  Scan &args(BasicObject &v1, BasicObject &v2, BasicObject &v3, BasicObject &v4)
    {
      args(v1, v2, v3);
      return arg(v4);
    }
  Scan &tail_arg(BasicObject &v1)
    {
      trace1("tail_arg, ArgC=%d", ArgC);
      if (GotOpt) rb_raise(rb_eFatal, "Scan: tail_arg[s]() must be given BEFORE opt[s]()");
      if (ArgC <= 0)
	rb_raise(rb_eArgError, "Scan: too few arguments (%d) given", OrgArgC);
      v1.assign(ArgV[--ArgC], SAFE);
      return *this;
    }
  Scan &tail_args(BasicObject &v1, BasicObject &v2)
    {
      tail_arg(v2);
      return tail_arg(v1);
    }
  Scan &opt(BasicObject &v1)
    {
      trace1("arg, ArgC=%d", ArgC);
      if (GotSplat) rb_raise(rb_eFatal, "Scan: options are obviously nil after splat() is called");
      GotOpt = true;
      if (ArgC <= 0)
	  v1.assign(Qnil, UNSAFE);
      else
	{
	  v1.assign(*ArgV, SAFE);
	  ArgC--, ArgV++;
	}
      return *this;
    }
  Scan &opts(BasicObject &v1, BasicObject &v2)
    {
      opt(v1);
      return opt(v2);
    }
  Scan &opts(BasicObject &v1, BasicObject &v2, BasicObject &v3)
    {
      opts(v1, v2);
      return opt(v3);
    }
  Scan &opts(BasicObject &v1, BasicObject &v2, BasicObject &v3, BasicObject &v4)
    {
      opts(v1, v2, v3);
      return opt(v4);
    }
  Scan &splat(Array &v); // FORWARDED
  //  Scan &hash(Hash &v);    BOGO, can just use tail_arg(hash).
  Scan &block(Proc &v); // FORWARDED

  // argc may change due to calls!
  int argc() const { return ArgC; }

  // argv may change due to calls!
  VALUE *argv() const { return ArgV; }

}; // class Scan

} // namespace RPP

#endif // _RPP_SCAN_H_
