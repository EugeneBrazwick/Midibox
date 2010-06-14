
# Copyright (c) 2010 Eugene Brazwick

require 'reform/app'

Reform::app {
  title tr('Icons')
  mainwindow { # optional (?)
    def changeIcon
      icon = Qt::Icon.new
      (0...imagesTable.rowCount).each do |row|
        item0 = imagesTable.item(row, 0)
        item1 = imagesTable.item(row, 1)
        item2 = imagesTable.item(row, 2)
        if item0.checkState == Qt::Checked
          mode = case item1.text
                 when tr('Normal') then Qt::Icon::Normal
                 when tr('Active') then Qt::Icon::Active
                 when tr('Disabled') then Qt::Icon::Disabled
                 else Qt::Icon::Selected
                 end
          state = item2.text == tr("On") ? Qt::Icon::On : Qt::Icon::Off
          fileName = item0.data(Qt::UserRole).toString
          image = Qt::Image.new(fileName)
          icon.addPixmap(QPixmap::fromImage(image), mode, state) unless image.null?
        end
      end
      previewArea.icon = icon
    end

    menuBar { # not a constructor but a reference
      menu { #   fileMenu = menuBar()->addMenu(tr("&File"));
        title tr('&File')
        action {
          text tr('&Add Images...')
          name :addImagesAct
          shortcut tr('Ctrl+A')
          whenTriggered do
            fileNames = Qt::FileDialog::getOpenFileNames(@qtc, tr('Open Images'), '',
                                                         tr('Images (*.png *.xpm *.gif *.jpg);;All Files (*)'))
            fileNames.each do |fileName|
              row = imagesTable.rowCount
              imagesTable.rowCount = row + 1
              imageName = File.basename(fileName)
              item0 = Qt::TableWidgetItem.new(imageName)
              item0.setData(Qt::UserRole, Qt::Variant.new(fileName))
              item0.flags &= ~Qt::ItemIsEditable
              item1 = Qt::TableWidgetItem.new(tr('Normal'))
              item2 = Qt::TableWidgetItem.new(tr('Off'))
              if guessModeStateAct.checked?
                item1.text = case fileName
                when /_act/ then tr('Active')
                when /_dis/ then tr('Disabled')
                else tr('Selected')
                end
                item2.text = tr('On') if fileName =~ /_on/
              end
              imagesTable.setItem(row, 0, item0)
              imagesTable.setItem(row, 1, item1)
              imagesTable.setItem(row, 2, item2)
              imagesTable.openPersistentEditor(item1)
              imagesTable.openPersistentEditor(item2)
              item0.checkState = Qt::Checked
            end # each
          end # whenTriggered
        }
        action {
          name :removeAllImagesAct
          text tr('&Remove All Images')
          shortcut tr('Ctrl+R')
          whenTriggered do
            imagesTable.rowCount = 0
            changeIcon
          end
        }
        separator
        action { # (exitAct);
          text tr('&Quit')
          shortcut Qt::KeySequence::Quit
          whenTriggered { close }
        }
      }
      menu { # viewMenu = menuBar()->addMenu(tr("&View"));
        title tr('&View')
        actiongroup {
          Qt::StyleFactory::keys.each do |styleName|
            action {
              connector :style  # supposedly a stylefactory key
              text tr('%s Style') % styleName
              checkable true
              value styleName      # the key itself, it works the same as a radio button
            }
          end
        }
        separator
        action {
          name :guessModeStateAct
          text tr('&Guess Image Mode/State')  # Has Second param. passed is mainwindow?? This hints that the
                  # qt parent must be the form.
          checked true
        }
      }
      separator # ignored in lucid. But it is added correctly
      menu { #  helpMenu = menuBar()->addMenu(tr("&Help"));
        title tr('&Help')
        action { # lpMenu->addAction(aboutAct);
          text tr('&About')
          whenTriggered do
            Qt::MessageBox::about(@qtc, tr('About Icons'),
                                  tr('The <b>Icons</b> example illustrates how Qt renders an icon in ' +
                                     'different modes (active, normal, disabled, and selected) and ' +
                                     'states (on and off) based on a set of images.'))
          end
        }
        action { #helpMenu->addAction(aboutQtAct);
          text tr('About &Qt')
          whenTriggered { $qApp.aboutQt }
        }
      } # helpmenu
    } # menuBar
    icon_example_model
    frame {  # centralWidget
      columnCount 2 # implicit grid...
      groupbox { # previewGroupBox
        title tr('Preview')
        colspan 2
        vbox {
          iconpreviewarea name: :previewArea
        }
      }
#       tag "HERE"
      groupbox { # imagesGroupBox
        title tr('Images')
        vbox {
          table {
            name :imagesTable
            contextMenu :addImagesAct, :removeAllImagesAct
#               policy Qt::ActionsContextMenu.   inferred by adding actions
#               action :addImagesAct, :removeAllImagesAct
#             }
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
            text_connector { |style| tr('Small (%d x %d)') % [m = style.metric, m] }
          }
          radio {
#             layoutpos: 1 # large
            value Qt::Style::PM_LargeIconSize
            connector :metric
            text_connector { |style| tr('Large (%d x %d)') % [m = style.metric, m] }
          }
          radio {
#             layoutpos: 2 # toolBar
            value Qt::Style::PM_ToolBarIconSize
            connector :metric
            text_connector { |style| tr('Toolbars (%d x %d)') % [m = style.metric, m] }
          }
          radio {
            value Qt::Style::PM_ListViewIconSize
            connector :metric
            text_connector { |style| tr('List views (%d x %d)') % [m = style.metric, m] }
          }
          radio {
            value Qt::Style::PM_IconViewIconSize
            connector :metric
            text_connector { |style| tr('Icon views (%d x %d)') % [m = style.metric, m] }
          }
          radio {
            value Qt::Style::PM_TabBarIconSize
            connector :metric
            text_connector { |style| tr('Tab bars (%d x %d)') % [m = style.metric, m] }
          }
          hbox { # otherSizeLayout
            colspan 3
            radio {
              text tr('Other:') # other
              # This is very interesting. We must now use the value of the spingbox as 'extent'
              # if checked then iconsizespinbox must be enabled and vice versa.
              value nil
              connector :metric
            }
            iconsizespinbox range: [8, 128], value: 64, connector: :extent, disabler: :metric
          } # hbox
          # ugly? way to add stretching row nr 4:
          rowStretch 4=>1
        } # grid
      } # iconSizeGroup
    }  # centralwidget
  } # mainwindow
} # app
