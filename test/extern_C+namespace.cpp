
// gcc -o /tmp/t2.so -shared extern_C+namespace.cpp
// objdump /tmp/t2.so	->   'cadang'
//  and			->   '_ZN9NameSpace16cadang_plus_plusEi'
// So, the NameSpace is completely ignored.
#include <stdio.h>

namespace NameSpace {

extern "C" void cadang(int i)
{
  printf("cadang(%d)\n", i);
}

void cadang_plus_plus(int i)
{
  printf("cadang++(%d)\n", i);
}

}


