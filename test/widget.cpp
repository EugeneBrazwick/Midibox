
// g++ -o main widget.cpp -I $QTDIR/include -fPIC -L $QTDIR/lib -lQt5Widgets

#include <QtWidgets/QWidget>
#include <QtWidgets/QApplication>

int main(int argc, char *argv[])
{
  QApplication app(argc, argv);
  /*
  QWidget * const window = new QWidget;
  window->setParent((QWidget *)&app);
  window->show();
  */
  //vs:
  QWidget window;
  window.show();
  return app.exec();
}
