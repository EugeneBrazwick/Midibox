
// gcc extra/dumpshapes.cpp -o /tmp/t -I /usr/include/qt4 -lQtCore -lQtGui

#include <Qt/qpainterpath.h>
#include <Qt/qfile.h>
#include <Qt/qdatastream.h>

int main()
{
  QFile *file = new QFile("./examples/painting/images/shapes.dat");
  file->open(QFile::ReadOnly);
  QDataStream * s = new QDataStream(file);
  printf("[");
  for(int i = 0; i < 4; i++)
  {
    if (i) printf(",\n\n");
    printf("[");
    QPainterPath p;
    *s >> p;
    // I used to source first (as in 'use the source Luke!'), see <QTUNTARPATH>/src/gui/painting/qpainterpath.cpp
    // But it used private methods of Q. The following destroys the path and is only an aproximation.
    QList<QPolygonF>pols = p.toSubpathPolygons();
    for (int j = 0; j < pols.count(); j++)
    {
      if (j) printf(",\n");
      QPolygonF poly = pols[j];
      printf("[");
      for (int k=0; k < poly.count(); k++)
      {
        if (k) printf(", ");
        const QPointF pt = poly[k];
        printf("{x: %f, y: %f}", double(pt.x()), double(pt.y()));
      }
      printf("]");
    }
    printf("]");
  }
  printf("]");
  return 0;
}
