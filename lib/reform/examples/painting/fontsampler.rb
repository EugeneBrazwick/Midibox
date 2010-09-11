
=begin
/****************************************************************************
 **
 ** Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies).
 ** All rights reserved.
 ** Contact: Nokia Corporation (qt-info@nokia.com)
 **
 ** This file is part of the examples of the Qt Toolkit.
 **
 ** $QT_BEGIN_LICENSE:LGPL$
 ** Commercial Usage
 ** Licensees holding valid Qt Commercial licenses may use this file in
 ** accordance with the Qt Commercial License Agreement provided with the
 ** Software or, alternatively, in accordance with the terms contained in
 ** a written agreement between you and Nokia.
 **
 ** GNU Lesser General Public License Usage
 ** Alternatively, this file may be used under the terms of the GNU Lesser
 ** General Public License version 2.1 as published by the Free Software
 ** Foundation and appearing in the file LICENSE.LGPL included in the
 ** packaging of this file.  Please review the following information to
 ** ensure the GNU Lesser General Public License version 2.1 requirements
 ** will be met: http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html.
 **
 ** In addition, as a special exception, Nokia gives you certain additional
 ** rights.  These rights are described in the Nokia Qt LGPL Exception
 ** version 1.1, included in the file LGPL_EXCEPTION.txt in this package.
 **
 ** GNU General Public License Usage
 ** Alternatively, this file may be used under the terms of the GNU
 ** General Public License version 3.0 as published by the Free Software
 ** Foundation and appearing in the file LICENSE.GPL included in the
 ** packaging of this file.  Please review the following information to
 ** ensure the GNU General Public License version 3.0 requirements will be
 ** met: http://www.gnu.org/copyleft/gpl.html.
 **
 ** If you have questions regarding the use of this file, please contact
 ** Nokia at qt-info@nokia.com.
 ** $QT_END_LICENSE$
 **
 ****************************************************************************/
=end

require 'reform/app'

Reform::app {
  mainwindow {

    def showFont item
      item or return
      if item.parent
        family = item.parent.text(0)
        style = item.text(0)
        weight = item.data(0, Qt::UserRole).to_i
        italic = item.data(0, Qt::UserRole + 1).to_i != 0
      else
        family = item.text(0)
        style = item.child(0).text(0)
        weight = item.child(0).data(0, Qt::UserRole).to_i
        italic = item.child(0).data(0, Qt::UserRole + 1).to_i != 0
      end
      textEdit.tap do |te|
        oldText = te.toPlainText.strip
        modified = te.document.modified?
        te.clear
        te.document.defaultFont = Qt::Font.new(family, 32, weight, italic)
        cursor = te.textCursor
        blockFormat = Qt::TextBlockFormat.new
        blockFormat.alignment = Qt::AlignCenter
        cursor.insertBlock(blockFormat)
        if modified
          cursor.insertText(oldText)
        else
          cursor.insertText("#{family} #{style}")
        end
        te.document.modified = modified
      end
    end # showFont

    def updateStyles item, column
#       tag "updateStyles(#{item}, #{column}), @markedCount = #@markedCount"
      return unless item && column == 0
      state = item.checkState(0)
      if parent = item.parent
        # Only count style items
        if state == Qt::Checked
          @markedCount += 1
        else
          @markedCount -= 1
        end
        if state == Qt::Checked && parent.checkState(0) == Qt::Unchecked
          parent.setCheckState(0, Qt::Checked)
        elsif state == Qt::Unchecked && parent.checkState(0) == Qt::Checked
          marked = false
          for row in 0 ... parent.childCount
            if parent.child(row).checkState(0) == Qt::Checked
              marked = true
              break
            end
          end
          # Unmark parent items when all child items are unchecked
          parent.setCheckState(0, Qt::Unchecked) unless marked
        end
      else
        number = 0
        for row in 0 ... item.childCount
          number += 1 if item.child(row).checkState(0) == Qt::Checked
        end
        # Mark/unmark all child items when marking/unmarking top-level items
        if state == Qt::Checked && number == 0
          for row in 0 ... item.childCount()
            item.child(row).setCheckState(0, Qt::Checked) if item.child(row).checkState(0) == Qt::Unchecked
          end
        elsif state == Qt::Unchecked && number > 0
          for row in 0 ... item.childCount()
            item.child(row).setCheckState(0, Qt::Unchecked) if item.child(row).checkState(0) == Qt::Checked
          end
        end
      end
#       tag "markedCount=#@markedCount"
      printAction.enabled = @markedCount > 0
      printPreviewAction.enabled = @markedCount > 0
    end

    def markFonts state
      fontTree.selectedItems.each { |item| item.setCheckState(0, state) unless item.checkState(0) == state }
    end

    def printPage(index, painter, printer)
      family = @pageMap.keys()[index];
      items = @pageMap[family];
      # Find the dimensions of the text on each page.
      width = 0.0;
      height = 0.0;
      items.each do |item|
        style = item.text(0);
        weight = item.data(0, Qt::UserRole).to_i;
        italic = item.data(0, Qt::UserRole + 1).to_i != 0;
        # Calculate the maximum width and total height of the text.
        @sampleSizes.each do |size|
          font = Qt::Font.new(family, size, weight, italic);
          font = Qt::Font.new(font, painter.device());
          fontMetrics = Qt::FontMetricsF.new(font);
          rect = fontMetrics.boundingRect("#{family} #{style}")
          width = [rect.width(), width].max
          height += rect.height();
        end
      end
      xScale = printer.pageRect().width() / width;
      yScale = printer.pageRect().height() / height;
      scale = [xScale, yScale].min
      remainingHeight = printer.pageRect().height()/scale - height;
      spaceHeight = (remainingHeight/4.0) / (items.count() + 1);
      interLineHeight = (remainingHeight/4.0) / (@sampleSizes.count() * items.count());
      painter.save();
      begin
        painter.translate(printer.pageRect().width()/2.0, printer.pageRect().height()/2.0);
        painter.scale(scale, scale);
        painter.setBrush(Qt::Brush.new(Qt::black));
        x = -width/2.0;
        y = -height/2.0 - remainingHeight/4.0 + spaceHeight;
        items.each do |item|
          style = item.text(0);
          weight = item.data(0, Qt::UserRole).to_i
          italic = item.data(0, Qt::UserRole + 1).to_i != 0;
          # Draw each line of text.
          @sampleSizes.each do |size|
            font = Qt::Font.new(family, size, weight, italic);
            font = Qt::Font.new(font, painter.device());
            # Note: in previewmode this fails for certain fonts. Like 'Andale Mono'
            # But not 'Arial'. And only BOLD. Maybe the font has no bold variation and it is
            # calculated wrongly.  However, the normal print is OK.
            fontMetrics = Qt::FontMetricsF.new(font);
            rect = fontMetrics.boundingRect("#{font.family} #{style}")
            y += rect.height();
            painter.setFont(font);
            painter.drawText(Qt::PointF.new(x, y), "#{family} #{style}");
            y += interLineHeight;
          end
          y += spaceHeight;
        end
      ensure
        painter.restore();
      end
    end # printPage

    def printDocument printer
      printer.setFromTo(1, @pageMap.count()); # this is WEIRD (Eugene)
      progress = Qt::ProgressDialog.new(tr("Preparing font samples..."), tr("&Cancel"),
                              0, @pageMap.count(), @qtc);
      progress.setWindowModality(Qt::ApplicationModal);
      progress.setWindowTitle(tr("Font Sampler"));
      progress.setMinimum(printer.fromPage() - 1);
      progress.setMaximum(printer.toPage());
      painter = Qt::Painter.new();
      painter.begin(printer);
      begin
        firstPage = true;
        for page in printer.fromPage() .. printer.toPage()
          printer.newPage() unless firstPage
          $qApp.processEvents();
          break if progress.wasCanceled();
          printPage(page - 1, painter, printer);
          progress.setValue(page);
          firstPage = false;
        end
      ensure
        painter.end();
      end
    end

    def currentPageMap()
      pageMap = {}
      for row in 0 ... fontTree.topLevelItemCount()
        familyItem = fontTree.topLevelItem(row);
        if (familyItem.checkState(0) == Qt::Checked)
          family = familyItem.text(0);
          pageMap[family] = []
        end
        for childRow in 0 ... familyItem.childCount()
          styleItem = familyItem.child(childRow);
          pageMap[family] << styleItem if (styleItem.checkState(0) == Qt::Checked)
        end
      end
      pageMap;
    end

    @sampleSizes = [32, 24, 16, 14, 12, 8, 4, 2 ,1]
    @markedCount = 0
    # somehow the first to call to updateStyles ruins markedCount

    def postSetup
      @markedCount = 0
      super # #Oh my .....
    end

    geometry 0, 0, 800, 345
    windowTitle tr('Font Sampler')
    frame { # centralWidget, will become the central widget automatically. If put in first.
#       tag "I am #@qtc"
#       centralWidget
      vbox {
        margin 9
        spacing 6
        textedit { name :textEdit }
      }
    }
    menubar {
      geometry 0, 0, 800, 24
      menu { # menu_File
        title tr('&File')
        action {
          name :printPreviewAction
          disabled
          text tr('Print Preview...')
          whenTriggered do
            @pageMap = currentPageMap
            return if @pageMap.count == 0
            printer = Qt::Printer.new(Qt::Printer::HighResolution)
            preview = Qt::PrintPreviewDialog.new(printer, @qtc)
            # the context here is the mainwindow (ie 'self'). So this can simply be done:
            connect(preview, SIGNAL('paintRequested(QPrinter*)'), self) { |prt| printDocument(prt) }
            preview.exec
          end
        }
        action {
          name :printAction
          disabled
          text tr('&Print...')
          shortcut tr('Ctrl+P')
          whenTriggered do
            @pageMap = currentPageMap
            return if @pageMap.count == 0
            printer = Qt::Printer.new(Qt::Printer::HighResolution)
            dialog = Qt::PrintDialog.new(printer, @qtc)
            return unless dialog.exec == Qt::Dialog::Accepted
            from = printer.fromPage
            to = printer.toPage
            printer.setFromTo(1, @pageMap.keys.count) if from <=0 && to <= 0
            printDocument printer
          end
        }
        action { # quit
          text tr('E&xit')
          shortcut :quit
          whenTriggered { $qApp.quit }
        }
      }
      menu { # menu_Selection
        title tr('&Selection')
        action { # mark
          text tr('&Mark')
          shortcut tr('Ctrl+M')
          whenTriggered { markFonts Qt::Checked }
        }
        action { # unmark
          text tr('&Unmark')
          shortcut tr('Ctrl+U')
          whenTriggered { markFonts Qt::Unchecked }
        }
        action {# clear
          text tr('&Clear')
          whenTriggered do
            currentItem = fontTree.currentItem
            fontTree.selectedItems.each { |item| fontTree.setItemSelected(item, false) }
            fontTree.setItemSelected(currentItem, true)
          end
        }
      } #menu
    } # menubar
    statusbar
    dock { # dockWidget
      features Qt::DockWidget::DockWidgetFloatable | Qt::DockWidget::DockWidgetMovable | Qt::DockWidget::NoDockWidgetFeatures
#       area :left              This is the default anyway
      windowTitle tr('Available Fonts')
        # FIXED: contents is utterly invisible!!!
#       sizeHint 400, 400 # DOES NOT WORK
      frame { # dockWidgetContents
        vbox {
          treewidget {
            name :fontTree
#             sizeHint 400, 400
            selectionMode Qt::AbstractItemView::ExtendedSelection
            columnCount 1
            whenCurrentItemChanged { |new, prev| showFont(new) }
            whenItemChanged { |item, colnr| updateStyles(item, colnr) }
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
            containing_form.showFont(topLevelItem(0))
          } # treewidget
          margin 16 # experimental, must be at least 16 to display an empty tree correctly (!?)
          spacing 6
        }
      } # dockWidgetContents
    } # dock
  } # mainwindow
} # app