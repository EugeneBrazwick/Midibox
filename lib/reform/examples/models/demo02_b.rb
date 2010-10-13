
require 'Qt'

include Qt

=begin from the Qt helppage:

Simple models can be created by subclassing this class and implementing the minimum number of
required functions. For example, we could implement a simple read-only QStringList-based model
that provides a list of strings to a QListView widget. In such a case, we only need
to implement the rowCount() function to return the number of items in the list, and the data()
                 ^^^^^^^^                                                               ^^^^
function to retrieve items from the list.


So I did that, and:
=end
class MyModel < AbstractListModel
  public

    Data = [ "Where's", "the", "walrus" ];

    def rowCount(parent)
      r = parent.isValid() ? 0 : Data.length()
      STDERR.printf("rowCount(%d) -> %d\n", parent.row, r); # 3 of course. Called very often
      return r;
    end

    def data(index, role = Qt::DisplayRole)
      STDERR.printf("data(%d, %d) (Qt::DisplayRole == %d) called, returning '%s'\n", index.row, role, Qt::DisplayRole, Data[index.row]);  # this is called. So why doesn't it work???
      # in particular 13.... If you return a string the size becomes invalid....
      if (!index.isValid() || role != Qt::DisplayRole)
        return Qt::Variant.new();
      end;
      r = qVariantFromValue(Data[index.row]);
      STDERR.printf("variant.value is %s\n", r.value.inspect);
      return r;
    end

end;


Application.new(ARGV);
list = ListView.new();
list.setWindowTitle("Artic landscape?");
list.setModel(MyModel.new(list));
list.show();
$qApp.exec();
