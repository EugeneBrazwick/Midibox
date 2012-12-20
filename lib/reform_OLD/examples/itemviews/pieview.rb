
# the pieview on its own

require 'reform/app'

# THERE ARE TOO MANY ISSUES WITH pieview or pieview_rd

MyData = [{ section: 'Scientific Research', count: 21, color: '#99e600'},
          { section: 'Engineering & Design', count: 18, color: '#99cc00'},
          { section: 'Automotive', count: 14, color: '#99b300'},
          { section: 'Aerospace', count: 13, color: '#9f991a'},
          { section: 'Automation & Machine Tools', count: 13, color: '#a48033'},
          { section: 'Medical & Bioinformatics', count: 13, color: '#a9664d'},
          { section: 'Imaging & Special Effects', count: 12, color: '#ae4d66'},
          { section: 'Defense', count: 11, color: '#b33380'},
          { section: 'Test & Measurement Systems', count: 9, color: '#a64086'},
          { section: 'Oil & Gas', count: 9, color: '#994d8d'},
          { section: 'Entertainment & Broadcasting', count: 7, color: '#8d5a93'},
          { section: 'Financial', count: 6, color: '#806699'},
          { section: 'Consumer Electronics', count: 4, color: '#8073a6'},
          { section: 'Other', count: 38, color: '#8080b3'}
      ]

Reform::app {
#   pieview {
  pieview_rd {          # Richard Dale original version
    struct MyData
    sizeHint 480, 300
=begin implicit declarations:
    column {
      decorator :color
      itemkey :section
      itemdisplay :section
    }
    column {
      itemdisplay :count
    }
=end
    decorator :color
    key_connector :section
    display_connector :section
    # only the next one is specific for pieview.
    value_connector :count
  }
}

__END__

How the reform Model connects in a generic fashion to Qt::AbstractList/Table/ItemModel

1) Why does Qt support all those models if the modelindex is basicly parent+row+column
anyway?

Can a QListView operate on any QAbstractItemModel implementation?

But we can do this to make it safe:

these modules contain the code that interfaces with Model (in particular Structure):
However, they gonna work from inside Qt::Models.

Module QAbstractItemModel; ... end
Module QAbstractListModel; include QAbstractItemModel; ... end
Module QAbstractTableModel; include QAbstractListModel; ... end

# these classes really are empty:
class QItemModel < Qt::AbstractItemModel; include QAbstractItemModel; end
class QModel < Qt::AbstractListModel; include QAbstractListModel; end
class QTableModel < Qt::AbstractTableModel; include QAbstractTableModel; end

# these are the delegators
class AbstractItemView < Widget; .... end
# with stuff specific for lists
class AbstractListView < AbstractItemView; ... end
# with stuff specific for tables
class AbstractTableView < AbstractListView; ... end

class List < AbstractListView; ... end
Matches QListView

class Table < AbstractTableView; ... end
Matches QTableView

# the following class has 'value_connector' for instance.
class PieView < AbstractItemView .... end

But Qt::Model basicly only has:
  - rowCount
  - colCount
  - data(row, col, role)

Note that the parent of that model is the reform-model.
Typically colCount is set in the view itself.

It's going to be problematic if the model has 0 rows.
If I have several rows then they should have the correct colcount.
But that would be the rowcount of the record at that point.
[{key: .., value: ...}, {key: .., value: .. },...]
This is a model. The outer array gives us rowcount, and the inner gives
us colcount, if we just peek the first row, and count the nr of keys.
Structure.length for a hash is the nr of keys in that hash.
So at that point can we start mapping columns to keys.

For QModel (in Reform::AbstractListView) it was easy enough.
Data was always retrieved using the display_connector, and the roles
used different connectors. And these were applied on 'The Record'.
So the core of QModel::data was:

    record.model_apply_getter(connector)

Not a column in site.

The solution is to use columns, where each column can have a set of
12 or so connectors (one for each role).
And the columncount to be displayed is decided by the containing table/view.
This view is already passed to the QItemModel.

Hence a pieview has 2 columns, where the deco of col1 is used and the display value
of col2 becomes the 'value'. Only tricky thing is the variant conversion required.
The reformmodel returns an integer but it will be stored in a variantstring, if
the :display connectorrole is used.
Unless we decide to use another role for it.
Can roles be tweaked from the view? I would say yes. That can solve the problem.
