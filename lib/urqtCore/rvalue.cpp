
// #define TRACE

// This document adheres to the GNU coding standard
// Copyright (c) 2013 Eugene Brazwick

#pragma implementation
#include "rvalue.h"
#include "api_utils.h"

namespace R_Qt {

int 
RVALUE_ID = QMetaType::UnknownType,
RGCGUARDEDVALUE_ID = QMetaType::UnknownType;

void 
init_rvalue()
{
  trace1("init_rvalue(%s)", STRINGIFY(T_RVALUE));
  traqt("qRegisterMetaType<T_RVALUE>");
  RVALUE_ID = qRegisterMetaType<T_RVALUE>(STRINGIFY(T_RVALUE));
  traqt("qRegisterMetaType<T_RGCGUARDEDVALUE>");
  RGCGUARDEDVALUE_ID = qRegisterMetaType<T_RGCGUARDEDVALUE>(STRINGIFY(T_RGCGUARDEDVALUE));
}

} // namespace R_Qt 

std::ostream &operator<<(std::ostream &o, const T_RVALUE &v)
{
  return o << *v;
}

std::istream &operator>>(std::istream &i, T_RVALUE &v)
{
  return v.read_from(i);
}

std::ostream &operator<<(std::ostream &o, const T_RGCGUARDEDVALUE &v)
{
  return o << *v;
}

std::istream &operator>>(std::istream &i, T_RGCGUARDEDVALUE &v)
{
  return v.read_from(i);
}
