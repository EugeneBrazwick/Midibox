
#include <qt4/QtCore/qdatastream.h>
#include <qt4/Qt/qpainterpath.h>
#include <ruby.h>

// Unfortunately it is not easy to see how qtruby wraps these classes.
// The following is incorrect! Although it does not crash....
static VALUE
wrap_read_painterpath(VALUE v_module, VALUE v_datastream, VALUE v_painterpath)
{
  QDataStream *ds;
  QPainterPath *path;
//   fprintf(stderr, "HERE\n");
  Data_Get_Struct(v_datastream, QDataStream, ds);
  fprintf(stderr, "device= %p\n", ds->device());
  fprintf(stderr, "openmode = 0x%x, THIS IS WRONG.... Do not call 'read_painterpath'!!!!\n", (int)ds->device()->openMode());
  Data_Get_Struct(v_painterpath, QPainterPath, path);
//   QDataStream *v = new QDataStream;
//   fprintf(stderr, "With a bit of luck, %p is a QDataStream ptr\n", ds); // , compare with %p\n", ds, v);
  *ds >> *path;
  return Qnil;
}

extern "C" void
Init_reform_internals()
{
  VALUE reformModule = rb_define_module("Reform");
  rb_define_module_function(reformModule, "read_painterpath", RUBY_METHOD_FUNC(wrap_read_painterpath), 2);
}