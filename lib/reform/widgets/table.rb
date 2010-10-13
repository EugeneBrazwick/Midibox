
# copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative 'widget'

=begin

TERRIBLE TRAGEDY

How do we connect the proper row of the model to the correct edit?

Apart from ColumnRef we also need a RowRef. Then updateModel can
assign the proper data.  Next, when the edit is created the rownr
is known so somehow we should be able to locate the Table itself,
so we can get the proper RowRef.  Actually a RowRef is only required
when the row is being edited. Assuming the model has a '[]' method that is.
Then we can parent the edit to the row, so the effectiveModel becomes the
record at that row!
Catching itemChanged is no longer required since the editor will now take
care of it.

It seems our hack to assign a reference from the reform control inside each qt control
becomes more important. We need to be able to step from Qt::TableWidget to Reform::Table.
Note however that the Qt::Editor is parented to some unknown widget (Qt::Widget, not
Qt::TableWidget)

NOTE: DEPRECATED CODE.

Use tableview until renamed.

It should work similar to ComboBox using AbstractTableView iso AbstractListView.
=end

  require 'reform/abstracttableview'

  class Table < AbstractTableView

      class HeaderRef < Qt::Object
        private
          def initialize qtable, qhdr, horizontal
            super()
            @qtable, @qtc, @horizontal = qtable, qhdr, horizontal
          end

          def defaultSectionSize value
            @qtc.defaultSectionSize = value
          end

          def stretchLastSection value #= nil
  #           return @qtc.stretchLastSection unless value
            @qtc.stretchLastSection = value
          end

          def labels *strings
            strings = strings[0] if strings.length == 1 && Array === strings[0]
            raise "please assign labels to the 'column' entries!" if @horizontal
#               tag "CALLING #{@qtable}.setHorizontalHeaderLabels(#{strings.inspect})"
#               @qtable.setHorizontalHeaderLabels strings
            @qtable.setVerticalHeaderLabels strings
          end

        public

          attr :qtc

          def setupQuickyhash hash
            hash.each { |k, v| send(k, v) }
          end

          def visible val = true
            if val
              @qtc.show
            else
              @qtc.hide
            end
          end
      end # class HeaderRef

      # a table will be made as an array of rowrefs, where each row basicly
      # caches the model at that row. This way we only need an Enumerable model
      # and not necessarily an array.
      # However it is very costly in terms of objects to be instantiated.
      class RowRef < Control
        private
        def initialize table, row
        end
      end

      class RubyDelegate < Qt::ItemDelegate
        private
          def initialize table, qtable
#             tag "RubyDelegate.new"
            super(table.containing_form.qtc)
            @table, @qtc = table, qtable
          end

        public
          # override.
          def createEditor qparent, option, index
#             tag "createEditor #{qparent}, opt=#{option}, index=#{index}"
            @table.col(index.column).createEditor(qparent, index.row)
          end

      end # class RubyDelegate

      class QTableModel < QModel
        public
#           def index(row, column, parent = Qt::ModelIndex.new)
#             return Qt::ModelIndex.new(
#           end
      end

      class TableColumnRef < ColumnRef
        include WidgetContext   # for the delegator only. Only 1 child is valid
        private
          def initialize header, view
            super(view)
            @header = header
            @qhdr header.qtc
            #             @persistent_editor = false
            @editor = nil
            @persistent_editor = nil # BAD IDEA:  :edit
          end

          def resizeMode mode
            @qhdr.setResizeMode(@n, mode)
          end

          def stretchMode val = true
            resizeMode Qt::HeaderView::Stretch
          end

          def fixedMode val = true
            resizeMode Qt::HeaderView::Fixed
          end

        public # TableColumnRef methods

          # does it have an editor?
          def editor?
            @persistent_editor || @editor
          end

          def persistent_editor value = nil
            return @persistent_editor if value.nil?
            @persistent_editor = value
          end

          def add child, quickyhash, &block
            child.setup quickyhash, &block
          end

          # should return Qt::Widget
          def createEditor qtparent, row
            if @editor
              @editor.name = @persistent_editor || :edit
              ctrl = @editor.exec self
            else
              ctrl = send(@persistent_editor || :edit)
            end
            ctrl.qtc.parent = qtparent
#               (quickyhash ||= {})[:qtparent] = qtparent
            ctrl.qtc
          end


      end # class TableColumnRef

    private # Table methods

      def initialize parent, qtc
        super
        @horizontalHeader = nil
        @qtc.verticalHeader.hide
#         connect(@qtc, SIGNAL('itemChanged(QTableWidgetItem *)')) do |item|
#           rfCallBlockBack(item, &@whenItemChanged) if instance_variable_defined?(:@whenItemChanged)
#           tag "itemChanged row=#{item.row}, col=#{item.column}"
#           row, col = item.row, item.column
#           column = @columns[col]
#           model = effectiveModel or next
#           cid = column.connector or next
#           next unless model.setter?(cid)
# #           model.row(row).apply_setter(cid, column.var2data(item.data(Qt::UserRole)))
#           model[row].apply_setter(cid, column.var2data(item.data(Qt::UserRole)))
#         end
#         tag "Calling RubyDelegate.new RubyDelegate=#{RubyDelegate}"
#         d = RubyDelegate.new(self, @qtc)
#         @qtc.itemDelegate = d
      end

      # override, factory method
      def createQModel
        QTableModel.new(@localmodel, self)
      end

      def horizontalHeader quickyhash = nil, &initblock
        @horizontalHeader = HeaderRef.new(@qtc, @qtc.horizontalHeader, true)
        @horizontalHeader.setupQuickyhash(quickyhash) if quickyhash
        @horizontalHeader.instance_eval(&initblock) if initblock
        @horizontalHeader
  #       ref.postSetup
      end

      def verticalHeader quickyhash = nil, &initblock
        ref = HeaderRef.new(@qtc, @qtc.verticalHeader, false)
        @qtc.verticalHeader.show
        ref.setupQuickyhash(quickyhash) if quickyhash
        ref.instance_eval(&initblock) if initblock
  #       ref.postSetup
        ref
      end

      def horizontalHeader!
        @horizontalHeader || horizontalHeader
      end

      def createColumnRef
        TableColumnRef.new(horizontalHeader!, self)
      end

      def setLocalModel aModel
        m = @qtc.selectionModel
        m.dispose if m
        super
      end

    public # table methods

      def col n
        @columns[n]
      end

      def setCurrentIndex idx
#         tag "Calling #{qmodel}.index(#{idx}, #{@qtc.modelColumn})"
        qmidx1 = (qmodel = @qtc.model).index(idx, 0) # ??? @qtc.modelColumn)
        qmidx2 = qmodel.index(idx, qmodel.columnCount - 1)
        sm = @qtc.selectionModel
        sm.select(Qt::ItemSelection.new(qmidx1, qmidx2), Qt::ItemSelectionModel::SelectCurrent);
        sm.setCurrentIndex(qmidx1, Qt::ItemSelectionModel::NoUpdate) # SelectCurrent)
      end

      def postSetup
#         tag "here" #, caller=#{caller.join("\n")}"
#         @qtc.columnCount = @columns.length
        if @horizontalHeader
          tag "setting labels and showing header"
          @qtc.horizontalHeaderLabels = @columns.map(&:label)
          @qtc.horizontalHeader.show
        else
          @qtc.horizontalHeader.hide
        end
      end

      def whenItemChanged &block
        raise "DISFUNCTIONAL code"
#         @whenItemChanged = block
      end

#       def rowCount= value
#         @qtc.rowCount = value
#       end

      # tables are truly row oriented
#       def setItem row, col, item
#         @qtc.setItem row, col, item
#       end

      def openPersistentEditor item
        @qtc.openPersistentEditor item
      end

      attr :columns
  end # class Table

  createInstantiator File.basename(__FILE__, '.rb'), Qt::TableView, Table

end