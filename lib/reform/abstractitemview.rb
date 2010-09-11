
#  Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative 'controls/widget'

  class AbstractItemView < Widget
    private
    define_simple_setter :selectionMode

    def whenCurrentItemChanged &block
      connect(@qtc, SIGNAL('currentItemChanged(QTreeWidgetItem*,QTreeWidgetItem*)'), self) do |current, prev|
        rfCallBlockBack(current, prev, &block)
      end
    end

    def whenItemChanged &block
      connect(@qtc, SIGNAL('itemChanged(QTreeWidgetItem*,int)'), self) { |item, colnr| rfCallBlockBack(item, colnr, &block) }
    end
  end

end

