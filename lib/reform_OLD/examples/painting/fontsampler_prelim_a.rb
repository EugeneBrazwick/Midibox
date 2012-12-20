
require 'reform/app'

Reform::app {
  mainwindow { # dockWidgetContents
    sizeHint 640, 480
    frame {
      vbox {
        margin 9
        spacing 6
        treewidget { # fontTree
          selectionMode Qt::AbstractItemView::ExtendedSelection
          name :fontTree
          stretch
          selectionMode Qt::AbstractItemView::ExtendedSelection
          columnCount 1
          headerLabels [tr('Font')]
  #             def postSetup             # DOES NOT HELP
          database = Qt::FontDatabase.new
          database.families.each do |family|
  #                 tag "iterating family #{family}"
            styles = database.styles(family)
            next if styles.empty?
            # manual: creating with parent will append the item in the tree.
            familyItem = Qt::TreeWidgetItem.new(@qtc)
            familyItem.setText(0, family)
            familyItem.setCheckState(0, Qt::Unchecked)
            styles.each do |style|
              styleItem = Qt::TreeWidgetItem.new(familyItem)
  #                 tag "new style item '#{style}'"
              styleItem.setText(0, style)
              styleItem.setCheckState(0, Qt::Unchecked)
              styleItem.setData(0, Qt::UserRole, Qt::Variant.new(database.weight(family, style)))
            end
          end
  #             end
          setItemSelected(topLevelItem(0), true)

        }
      }
    }
  }
}