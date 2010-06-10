
# Copyright (c) 2010 Eugene Brazwick

require 'reform/app'

Reform::app {
  title tr('Icons')
  mainwindow {
    frame {  # centralWidget
      central # FIXME: if a mainwindow has only 1 child, make that the central widget
      columnCount 2 # implicit grid...
      groupbox { # previewGroupBox
        title tr('Preview')
        colspan 2
        vbox {
          iconpreviewarea { # previewArea
          }
        }
      }
      groupbox { # imagesGroupBox
        title tr('Images')
        vbox {
          table { # imagesTable
            noSelection
            # this must become a model!!
            imagedelegate  # IMPORTANT: the parent must be the main window
                # AND: what the hell is a delegate???
                # A: the instance that actually draws the item within a table.
                # if a model is shared in more than one view, each view must have its own
                # delegate. However the view does NOT take ownership.
            horizontalHeader { # this is not a constructor, but a reference
              defaultSectionSize 90
              column label: tr('Image'), stretchMode: true
              column label: tr('Mode'), fixedMode: true
              column label: tr('State'), fixedMode: true
            }
            verticalHeader visible: false
            whenItemChanged do
              changeIcon
            end
          }
        } # vbox
      } # group
      groupbox {
        title tr('Icon Size')
        gridlayout { # grid can maybe be implicit, if rowStretch would work.
                     # MAYBE: spacer stretch: 1, colspan: 3
          columnCount 3
          radio {
#             layoutpos: 0 # small
            value Qt::Style::PM_SmallIconSize
            connector :metric
          }
          radio {
#             layoutpos: 1 # large
            value Qt::Style::PM_LargeIconSize
            connector :metric
          }
          radio {
#             layoutpos: 2 # toolBar
            value Qt::Style::PM_ToolBarIconSize
            connector :metric
          }
          radio value: Qt::Style::PM_ListViewIconSize, connector: :metric
          radio value: Qt::Style::PM_IconViewIconSize, connector: :metric
          radio value: Qt::Style::PM_TabBarIconSize, connector: :metric
          hbox { # otherSizeLayout
            colspan 3
            radio {
              text tr('Other:') # other
              # This is very interesting. We must now use the value of the spingbox as 'extent'
              # if checked then iconsizespinbox must be enabled and vice versa. FIXME HOW????
              value nil
              connector :metric
            }
            iconsizespinbox range: [8, 128], value: 64, connector: :extent
          } # hbox
          # ugly? way to add stretching row nr 4:
          rowStretch 4=>1
        } # grid
      } # iconSizeGroup
    }  # centralwidget
  } # mainwindow
} # app
