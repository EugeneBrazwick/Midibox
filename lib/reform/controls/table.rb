
# copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative 'widget'

  class Table < Widget
    include ModelContext
    private

    def initialize parent, qtc
      super
      @horizontalHeader = nil
      @qtc.verticalHeader.hide
      @columns = []
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

    class ColumnRef < Qt::Object
      private
      def initialize header, table
        super()
#         tag "new ColumnRef(#{header})"
        @header, @table, @qhdr, @n = header, table, header.qtc, table.columns.length
        @connector = nil
        @label = ''
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

      # sets the 'creator' like :combobox or :edit. Unset means :edit
      # unless there is a @model_connector, then we use :combobox as default
      def editor value
        @editor = value
      end

      public

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

    def connectModel aModel, options = nil
      tag "connectModel #{aModel}, len=#{aModel.length}"
      @data = aModel
      @qtc.clearContents
      if aModel then
        @qtc.rowCount = aModel.length
        @data.each_with_index do |entry, row|
          tag "There are #{@columns.length} columns, entry = #{entry.class} #{entry}"
          @columns.each_with_index do |col, n|
            tag "n=#{n}, cid = '#{col.connector}'"
            if cid = col.connector then
              if entry.getter?(cid) then
                value = entry.apply_getter(cid)
                tag "cid=#{cid}, colno=#{n}, row=#{row}, value = #{value.class} #{value}"
                item = Qt::TableWidgetItem.new(value.to_s)
                @qtc.setItem(row, n, item)
              else
                tag "Not a getter: #{entry.class}::#{cid}"
              end
            end
          end
        end
      else
        @qtc.rowCount = 0
      end
      super
    end  # connectModel

    attr :columns
  end # class Table

  createInstantiator File.basename(__FILE__, '.rb'), Qt::TableWidget, Table

end