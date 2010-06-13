
# copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative 'widget'

  class Table < Widget
    include ModelContext
    private
    define_simple_setter :selectionMode, :rowCount

    def noSelection
      selectionMode Qt::AbstractItemView::NoSelection
    end

    class HeaderRef < Qt::Object
      private
      def initialize table, hdr
        super()
        @table, @hdr, @ncols, @labels = table, hdr, 0, []
      end

      def defaultSectionSize value
        @hdr.defaultSectionSize = value
      end

      class ColumnRef
        private
        def initialize header, table, hdr, n
          @header, @table, @hdr, @n = header, table, hdr, n
        end

        def label lab
          @header.labels << lab
        end

        def resizeMode mode
          @hdr.setResizeMode(@n, mode)
        end

        def stretchMode val = true
          resizeMode Qt::HeaderView::Stretch
        end

        def fixedMode val = true
          resizeMode Qt::HeaderView::Fixed
        end

        public
        def setupQuickyhash hash
          hash.each { |k, v| send(k, v) }
        end

      end

      def column quickyhash = nil, &initblock
        ref = ColumnRef.new(self, @table, @hdr, @ncols)
        @ncols += 1
        if quickyhash
          ref.setupQuickyhash(quickyhash)
        else
          ref.instance_eval(&initblock)
        end
      end

      public

      attr :labels

      def setupQuickyhash hash
        hash.each { |k, v| send(k, v) }
      end

      def postSetup
        @table.horizontalHeaderLabels = @labels
      end

      def visible val = true
        if val
          @hdr.show
        else
          @hdr.hide
        end
      end
    end # class HeaderRef

    def horizontalHeader quickyhash = nil, &initblock
      ref = HeaderRef.new(@qtc, @qtc.horizontalHeader)
      if quickyhash
        ref.setupQuickyhash(quickyhash)
      else
        ref.instance_eval(&initblock)
      end
      ref.postSetup
    end

    def verticalHeader quickyhash = nil, &initblock
      ref = HeaderRef.new(@qtc, @qtc.verticalHeader)
      if quickyhash
        ref.setupQuickyhash(quickyhash)
      else
        ref.instance_eval(&initblock)
      end
      ref.postSetup
    end

    public

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
  end

  createInstantiator File.basename(__FILE__, '.rb'), Qt::TableWidget, Table

end