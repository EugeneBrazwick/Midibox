
#include <QtWidgets/QApplication>
#include <ruby.h>

extern "C" void
Init_liburqt()
{
  fprintf(stderr, "Euh?\n");
}
