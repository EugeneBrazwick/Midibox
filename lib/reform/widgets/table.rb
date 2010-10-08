
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
  class Table < Widget
    include ModelContext
    private

      def initialize parent, qtc
        super
        @horizontalHeader = nil
        @qtc.verticalHeader.hide
        @columns = []
        connect(@qtc, SIGNAL('itemChanged(QTableWidgetItem *)')) do |item|
          rfCallBlockBack(item, &@whenItemChanged) if instance_variable_defined?(:@whenItemChanged)
          tag "itemChanged row=#{item.row}, col=#{item.column}"
          row, col = item.row, item.column
          column = @columns[col]
          model = effectiveModel or next
          cid = column.connector or next
          next unless model.setter?(cid)
#           model.row(row).apply_setter(cid, column.var2data(item.data(Qt::UserRole)))
          model[row].apply_setter(cid, column.var2data(item.data(Qt::UserRole)))
        end
        tag "Calling RubyDelegate.new RubyDelegate=#{RubyDelegate}"
        d = RubyDelegate.new(self, @qtc)
        @qtc.itemDelegate = d
      end

      define_simple_setter :selectionMode, :rowCount

      def noSelection
        selectionMode Qt::AbstractItemView::NoSelection
      end

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

      # a table will be made as an array of rowrefs, where each row basicly
      # caches the model at that row. This way we only need an Enumerable model
      # and not necessarily an array.
      # However it is very costly in terms of objects to be instantiated.
      class RowRef < Control
        private
        def initialize table, row
        end
      end

      class ColumnRef < Control
        include WidgetContext
        private
          def initialize header, table
            super(table, nil)
    #         tag "new ColumnRef(#{header})"
            @header, @table, @qhdr, @n = header, table, header.qtc, table.columns.length
            @connector = nil
            @label = ''
            @type = String
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

#           # This class seems to be not more than a simple macro. Used to instantiate
#           # the real editor later on
#           class ColumnEditor
#             private
#
#               # the block + hash passed here are in the end send to the instantiator.
#               def initialize quickyhash, block
#                 @klass, @quickyhash, @initblock = nil, quickyhash, block
#               end
#
#             public
#
#               # set the 'editor' class like :edit or :combobox. This is a symbol,
#               # and will be used as instantiator
#               def klass value = nil
#                 return (@klass || :edit) if value.nil?
#                 @klass = value
#               end
#
#               attr :quickyhash, :initblock
#           end # class ColumnEditor

          # sets the 'creator' like :combobox or :edit. Unset means :edit
          # unless there is a @model_connector, then we use :combobox as default
          def editor quickyhash = nil, &block
#             @persistent_editor
            @editor = Macro.new(nil, nil, quickyhash, block)
    #         @qtc.itemDelegate = @editor
          end

        public

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

          def type value = nil
            return @type if value.nil?
            @type = value
          end

          def var2data variant
            tag "var2data, type = #{@type.inspect}"
            # IMPORTANT: String === String results in false!!!
            case @type.to_s
            when 'String' then variant.to_string
            when 'TrueClass', 'FalseClass' then variant.toBool
            when 'Integer' then variant.toInt
            when 'Float' then variant.toFloat
            else raise ReformError, "Missing method to convert Qt::Variant to a '#@type'. Please complain."
            end
          end

          def connector con = nil, &block
            return @connector unless con || block
            @connector = block ? block : con
            want_data! #!
          end

#           def model_connector con = nil, &block
#             return @model_connector unless con || block
#             @model_connector = block ? block : con
#           end

          def setupQuickyhash hash
            hash.each { |k, v| send(k, v) }
          end

          def label lab = nil
            return @label if lab.nil?
            @label = lab
          end

      end # class ColumnRef

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

      def horizontalHeader!
        @horizontalHeader || horizontalHeader
      end

      def column quickyhash = nil, &initblock
        @columns << (ref = ColumnRef.new(horizontalHeader!, self))
        if quickyhash
          ref.setupQuickyhash(quickyhash)
        else
          ref.instance_eval(&initblock)
        end
      end

    public

      def col n
        @columns[n]
      end

      def postSetup
#         tag "here" #, caller=#{caller.join("\n")}"
        @qtc.columnCount = @columns.length
        if @horizontalHeader
          tag "setting labels and showing header"
          @qtc.horizontalHeaderLabels = @columns.map(&:label)
          @qtc.horizontalHeader.show
        else
          @qtc.horizontalHeader.hide
        end
      end

      def whenItemChanged &block
        @whenItemChanged = block
      end

      def rowCount= value
        @qtc.rowCount = value
      end

      # tables are truly row oriented
      def setItem row, col, item
        @qtc.setItem row, col, item
      end

      def openPersistentEditor item
        @qtc.openPersistentEditor item
      end

      def updateModel aModel, propagation
        tag "updateModel #{aModel}, len=#{aModel.length}, propagation = #{propagation.inspect}"
        @data = aModel
        if cid = connector && aModel.getter?(cid)
          @data = aModel.apply_getter(cid)
        end
        no_signals do
          @qtc.clearContents
          if @data then
            if propagation.init?
              @qtc.rowCount = @data.length
#               tag "CALLING EACH_WITH_INDEX"
              @data.each_with_index do |entry, row|
#                 tag "row=#{row}, there are #{@columns.length} columns, entry = #{entry.class} #{entry.inspect}"
                @columns.each_with_index do |col, n|
#                   tag "row=#{row}, n=#{n}, cid = '#{col.connector}, entry = #{entry}'"
                  if cid = col.connector then
                    if entry.getter?(cid) then
                      value = entry.apply_getter(cid)
#                       tag "cid=#{cid}, colno=#{n}, row=#{row}, value = #{value.class} #{value}"
                      if value.respond_to?(:to_str)
                        item = Qt::TableWidgetItem.new(value.to_str)
                      else
                        item = Qt::TableWidgetItem.new
                        item.setData Qt::DisplayRole, Qt::Variant.from_value(value)
                      end
                      @qtc.setItem(row, n, item)
                      if col.editor?
#                         tag "create persistent_editor, n=#{n}, item=#{item}"
                        @qtc.openPersistentEditor(item)
                      end
                      if entry.setter?(cid)
                        item.flags |= Qt::ItemIsEditable.to_i
                      else
                        item.flags &= ~(Qt::ItemIsEditable.to_i)
                      end
                    else
#                       tag "Not a getter: #{entry.class}::#{cid}"
                    end
                  end
                end # each column
              end  # each data
#               tag "done EACH_WITH_INDEX"
            end
          end
        end
#         propagat      eModel aModel, propagation              BAD IDEA!
      end  # updateModel

      attr :columns
  end # class Table

  createInstantiator File.basename(__FILE__, '.rb'), Qt::TableWidget, Table

end