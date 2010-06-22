
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
        tag "itemChanged row=#{item.row}, col=#{item.column}"
        row, col = item.row, item.column
        column = @columns[col]
        model = effectiveModel or next
        cid = column.connector or next
        next unless model.setter?(cid)
        model.row(row).apply_setter(cid, column.var2data(item.data(Qt::UserRole)))
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
      def initialize qtable, qhdr
        super()
        @qtable, @qtc = qtable, qhdr
      end

      def defaultSectionSize value
        @qtc.defaultSectionSize = value
      end

      public

      attr :qtc

      def setupQuickyhash hash
        hash.each { |k, v| send(k, v) }
      end

      # override
#       def postSetup
#         tag "here" #, caller=#{caller.join("\n")}"
#         @qtable.horizontalHeaderLabels = @labels
#       end # HeaderRef#postSetup

      def visible val = true
        if val
          @qtc.show
        else
          @qtc.hide
        end
      end
    end # class HeaderRef

    def horizontalHeader quickyhash = nil, &initblock
      @horizontalHeader = HeaderRef.new(@qtc, @qtc.horizontalHeader)
      @horizontalHeader.setupQuickyhash(quickyhash) if quickyhash
      @horizontalHeader.instance_eval(&initblock) if initblock
      @horizontalHeader
#       ref.postSetup
    end

    def verticalHeader quickyhash = nil, &initblock
      ref = HeaderRef.new(@qtc, @qtc.verticalHeader)
      @qtc.verticalHeader.show
      ref.setupQuickyhash(quickyhash) if quickyhash
      ref.instance_eval(&initblock) if initblock
#       ref.postSetup
      ref
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
        @persistent_editor = false
        @editor = nil
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

      class ColumnEditor
        private

        def initialize quickyhash, block
          @klass, @quickyhash, @initblock = nil, quickyhash, block
        end

        public

        def klass value = nil
          return (@klass || :edit) if value.nil?
          @klass = value
        end

        attr :quickyhash, :initblock
      end # class ColumnEditor

      # sets the 'creator' like :combobox or :edit. Unset means :edit
      # unless there is a @model_connector, then we use :combobox as default
      def editor quickyhash = nil, &block
        @editor = ColumnEditor.new(quickyhash, block)
#         @qtc.itemDelegate = @editor
      end

      public

      def persistent_editor value = nil
        return @persistent_editor if value.nil?
        @persistent_editor = value
      end

      def add child, quickyhash, &block
        child.setup quickyhash, &block
      end

      # should return Qt::Widget
      def createEditor qtparent, row
        if ed = @editor
          quickyhash, initblock = ed.quickyhash, ed.initblock
          (quickyhash ||= {})[:qtparent] = qtparent
        else
          quickyhash = { qtparent: qtparent }
          initblock = nil
        end
        tag "calling #{self}::#{ed && ed.klass}"
        ctrl = send(ed && ed.klass || :edit, quickyhash, &initblock)
#       ctrl.connector = self.connector       NO. The table already responds and it knows the proper rowdata,
        # or at least it knows it better than the edit.
        # but when it is a combo????
        ctrl.qtc
      end

      def type value = nil
        return @type if value.nil?
        @type = value
      end

      def var2data variant
        case @type
        when String then variant.to_string
        when TrueClass, FalseClass then variant.toBool
        when Integer then variant.toInt
        when Float then variant.toFloat
        else raise ReformError, "Missing method to convert Qt::Variant to a '#@type'. Please complain."
        end
      end

      def connector con = nil, &block
        return @connector unless con || block
        @connector = block ? block : con
      end

      def model_connector con = nil, &block
        return @model_connector unless con || block
        @model_connector = block ? block : con
      end

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
        tag "RubyDelegate.new"
        super(table.containing_form.qtc)
        @table, @qtc = table, qtable
      end

      public
      # override.
      def createEditor qparent, option, index
        tag "createEditor #{qparent}, opt=#{option}, index=#{index}"
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
      tag "here" #, caller=#{caller.join("\n")}"
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
      connect(@qtc, SIGNAL('itemChanged(QTableWidgetItem *)')) { |item| rfCallBlockBack(item, &block) }
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

    def updateModel aModel, options = nil
      tag "updateModel #{aModel}, len=#{aModel.length}"
      @data = aModel
      if cid = connector && aModel.getter?(cid)
        @data = aModel.apply_getter(cid)
      end
      @qtc.clearContents
      if @data then
        if options[:initialize]
          @qtc.rowCount = @data.length
          @data.each_with_index do |entry, row|
            tag "There are #{@columns.length} columns, entry = #{entry.class} #{entry}"
            @columns.each_with_index do |col, n|
              tag "n=#{n}, cid = '#{col.connector}'"
              if cid = col.connector then
                if entry.getter?(cid) then
                  value = entry.apply_getter(cid)
                  tag "cid=#{cid}, colno=#{n}, row=#{row}, value = #{value.class} #{value}"
                  item = Qt::TableWidgetItem.new(value.respond_to?(:to_str) ? value.to_str : value.to_s)
                  @qtc.setItem(row, n, item)
                  if col.persistent_editor
                    tag "create persistent_editor, n=#{n}, item=#{item}"
                    @qtc.openPersistentEditor(item)
                  end
                  if entry.setter?(cid)
                    item.flags |= Qt::ItemIsEditable.to_i
                  else
                    item.flags &= ~(Qt::ItemIsEditable.to_i)
                  end
                else
                  tag "Not a getter: #{entry.class}::#{cid}"
                end
              end
            end
          end
        end
      end
      super
    end  # updateModel

    attr :columns
  end # class Table

  createInstantiator File.basename(__FILE__, '.rb'), Qt::TableWidget, Table

end