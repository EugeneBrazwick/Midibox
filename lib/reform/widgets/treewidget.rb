#  Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative '../abstractitemview'

  # a TreeWidget is a simplified TreeView, where each item is a Qt::TreeWidgetItem
  class TreeWidget < AbstractItemView
    private

    define_simple_setter :columnCount, :headerLabels
    def_delegators :@qtc, :setItemSelected, :topLevelItem, :selectedItems, :currentItem,
                          :topLevelItemCount
  end

  createInstantiator File.basename(__FILE__, '.rb'), Qt::TreeWidget, TreeWidget

end

