
/*
gcc -o /tmp/t -fPIC test/abstractlistview.cpp -I /usr/include/qt4/QtCore -I /usr/include/qt4/QtGui/ \
  -I /usr/include/qt4 -L /usr/lib/ -lQtCore -lQtGui
*/

/* from the Qt helppage:

Simple models can be created by subclassing this class and implementing the minimum number of
required functions. For example, we could implement a simple read-only QStringList-based model
that provides a list of strings to a QListView widget. In such a case, we only need
to implement the rowCount() function to return the number of items in the list, and the data()
                 ^^^^^^^^                                                               ^^^^
function to retrieve items from the list.

So I did that, and:
*/

#include <QAbstractItemModel>
#include <QApplication>
#include <QListView>
#include <stdio.h> // yeah I know

QString Data[3] = { "Where's", "the", "walrus" };

class MyModel: public QAbstractListModel
{
  public:
    MyModel(QObject *parent = 0): QAbstractListModel(parent) {}
    int rowCount(const QModelIndex &parent) const
      {
        return 3;
      }
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const
      {
        if (!index.isValid() || role != Qt::DisplayRole)
          {
//             fprintf(stderr, "Does happen, role = %d, dp = %d\n", role, Qt::DisplayRole);
            return QVariant();
          }
        // IMPORTANT: return only DisplayRole requests.....  Otherwise it will return colors + fonts == invalid....
        return Data[index.row()];
      }
};

int main(int argc, char *argv[])
{
  QApplication * const app = new QApplication(argc, argv);
  QListView * const list = new QListView();
  list->setWindowTitle("Artic landscape?");
  list->setModel(new MyModel(list));
  list->show();
  app->exec();
  return 0;
}



