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

# Copyright (c) 2010 Eugene Brazwick

=begin
Unfortunately the << Qt::DataStream operation is broken. It may be a ruby1.9.1 issue,
but the example in kdebindings is also not working.

So I changed the mimetype to 'text/yaml'

But then I noticed Qt objects are stored as empty hashes....
Bummer...
=end

require 'reform/app'
require 'reform/widgets/list'
require 'yaml'

module Reform
  # IMPORTANT: compare this to the fridgewidgets example. It is almost standard!!
  class QPiecesList < Qt::ListWidget
    protected
      # override
      def dragEnterEvent event
        if event.mimeData.hasFormat('image/x-puzzle-piece')
          event.accept
        else
          event.ignore
        end
      end

      # override
      def dragMoveEvent event
        if event.mimeData.hasFormat('image/x-puzzle-piece')
          event.dropAction = Qt::MoveAction
          event.accept
        else
          event.ignore
        end
      end

      # override
      def dropEvent event
        if event.mimeData.hasFormat('image/x-puzzle-piece')
          pieceData = event.mimeData.data('image/x-puzzle-piece')
          dataStream = Qt::DataStream.new(pieceData, Qt::IODevice::ReadOnly)
          pixmap = Qt::Variant.new
          location = Qt::Point.new
          dataStream >> pixmap >> location
          addPiece(pixmap.value, location.x, location.y)
          event.setDropAction(Qt::MoveAction)
          event.accept
        else
          event.ignore
        end
      end

      # override
      def startDrag supportedActions
        item = currentItem
        itemData = Qt::ByteArray.new
        dataStream = Qt::DataStream.new(itemData, Qt::IODevice::WriteOnly)
        pixmap = item.data(Qt::UserRole).value
        location = item.data(Qt::UserRole + 1).value
        dataStream << Qt::Variant::from_value(pixmap) << location
        mimeData = Qt::MimeData.new
        mimeData.setData('image/x-puzzle-piece', itemData)
        drag = Qt::Drag.new(self)
        drag.mimeData = mimeData
        drag.hotSpot = Qt::Point.new(pixmap.width / 2, pixmap.height / 2)
        takeItem(row(item)) if drag.exec(Qt::MoveAction) == Qt::MoveAction
          # NOTE: delete or deleteLater does not work in qtruby, I think (== hope) by design
      end

    public
      def addPiece pixmap, x, y
        pieceItem = Qt::ListWidgetItem.new(self)
        pieceItem.icon = Qt::Icon.new(pixmap)
#         tag "addPiece(#{pixmap}, #{x}, #{y})"
        pieceItem.setData(Qt::UserRole, Qt::Variant::fromValue(pixmap))
        pieceItem.setData(Qt::UserRole + 1, Qt::Variant.new(Qt::Point.new(x, y)))
        pieceItem.setFlags(Qt::ItemIsEnabled | Qt::ItemIsSelectable | Qt::ItemIsDragEnabled)
      end

      def shuffle
        (0...count).each do |i|
          if rand(2) == 1
            item = takeItem(i)
            insertItem(0, item)
          end
        end
      end
  end

  class PiecesList < ListView
    private
      def_delegators :@qtc, :addPiece, :shuffle, :clear

  end

  registerKlass Widget, :pieceslist, QPiecesList, PiecesList

  class QPuzzelWidget < QWidget
    private
      def initialize parent
        super
        @piecePixmaps = []
        @pieceRects = []
        @pieceLocations = []
        @highlightedRect = Qt::Rect.new
        @inPlace = 0
        setAcceptDrops true
        setMinimumSize 400, 400
        setMaximumSize 400, 400
      end

      def findPiece pieceRect
        @pieceRects.find_index(pieceRect)
      end

      def targetSquare position
        Qt::Rect.new((position.x / 80) * 80, (position.y / 80) * 80, 80, 80)
      end

    protected
      def dragEnterEvent event
        if event.mimeData.hasFormat('image/x-puzzle-piece')
          event.accept
        else
          event.ignore
        end
      end

      def dragLeaveEvent event
        updateRect = @highlightedRect
        @highlightedRect = Qt::Rect.new
        update(updateRect)
        event.accept
      end

      def dragMoveEvent event
        updateRect = @highlightedRect.unite(targetSquare(event.pos))
        if event.mimeData.hasFormat('image/x-puzzle-piece') &&
          !findPiece(targetSquare(event.pos))
          @highlightedRect = targetSquare(event.pos)
          event.dropAction = Qt::MoveAction
          event.accept
        else
          @highlightedRect = Qt::Rect.new
          event.ignore
        end
        update updateRect
      end

      def dropEvent event
        if event.mimeData.hasFormat('image/x-puzzle-piece') &&
          !findPiece(targetSquare(event.pos))
          pieceData = event.mimeData.data('image/x-puzzle-piece')
          dataStream = Qt::DataStream.new(pieceData, Qt::IODevice::ReadOnly)
          square = targetSquare(event.pos)
          pixmap = Qt::Variant.new
          location = Qt::Point.new
          dataStream >> pixmap >> location
          @pieceLocations << location
          @piecePixmaps << pixmap.value
          @pieceRects << square
          @highlightedRect = Qt::Rect.new
          update(square)
          event.dropAction = Qt::MoveAction
          event.accept
          if (location.x == square.x / 80 && location.y == square.y / 80)
            @inPlace += 1
            if @inPlace == 25
              completed
            end
          end
        else
          @highlightedRect = Qt::Rect.new
          event.ignore
        end
      end

      def mousePressEvent event
        square = targetSquare(event.pos)
        found = findPiece(square) or return
        location = @pieceLocations[found]
        pixmap = @piecePixmaps[found]
        @pieceLocations.delete_at(found)
        @piecePixmaps.delete_at(found)
        @pieceRects.delete_at(found)
        if location.x == square.x / 80 && location.y == square.y / 80
          @inPlace -= 1
        end
        update square
        itemData = Qt::ByteArray.new('')
        dataStream = Qt::DataStream.new(itemData, Qt::IODevice::WriteOnly.to_i)
        dataStream << Qt::Variant::from_value(pixmap) << location
        mimeData = Qt::MimeData.new
        mimeData.setData 'image/x-puzzle-piece', itemData
        drag = Qt::Drag.new self
        drag.mimeData = mimeData
        drag.hotSpot = event.pos - square.topLeft
        drag.pixmap = pixmap
        unless drag.exec(Qt::MoveAction) == Qt::MoveAction
          @pieceLocations.insert(found, location)
          @piecePixmaps.insert(found, pixmap)
          @pieceRects.insert(found, square)
          update targetSquare(event.pos)
          if location.x == square.x / 80 && location.y == square.y / 80
            @inPlace += 1
          end
        end
      end

      def paintEvent event
        painter = Qt::Painter.new
        painter.begin(self)
        begin
          painter.fillRect(event.rect, Qt::Brush.new(Qt::Color.new(Qt::white)))
          if @highlightedRect.valid?
            painter.brush = Qt::Brush.new(Qt::Color.new('#ffcccc'))
            painter.pen = Qt::NoPen
            painter.drawRect(@highlightedRect.adjusted(0, 0, -1, -1))
          end
          @pieceRects.each_with_index do |rect, i|
            painter.drawPixmap(rect, @piecePixmaps[i])
          end
        ensure
          painter.end
        end
      end

    public

      def completed
        @_reform_hack.whenCompleted
      end

      def clear
        @piecePixmaps = []
        @pieceRects = []
        @pieceLocations = []
        @highlightedRect = Qt::Rect.new
        @inPlace = 0
        update
      end
  end

  class PuzzleWidget < Widget
    public

      def_delegators :@qtc, :clear

      def whenCompleted &block
        if block
          @whenCompleted = block
        elsif instance_variable_defined?(:@whenCompleted)
          rfCallBlockBack(&@whenCompleted)
        end
      end
  end

  registerKlass Widget, :puzzlewidget, QPuzzelWidget, PuzzleWidget
end # Reform

Reform::app {
  mainwindow {
    puzzleImage = Qt::Pixmap.new
    def openImage file = nil
      unless file
        file = Qt::FileDialog.getOpenFileName(@qtc, tr('Open Image'), '',
                                              'Image Files (*.png, *.jpg)')
      end
      if file && !file.empty?
        newImage = Qt::Pixmap.new
        unless newImage.load(file)
          Qt::MessageBox::warning(@qtc, tr('Open Image'),
                                  tr('The image file could not be loaded.'),
                                  Qt::MessageBox::Cancel)
          return
        end
        @puzzleImage = newImage
        restart.whenClicked
      end
    end
    menubar {
      menu { # fileMenu
        title tr('&File')
        action {
          title tr('&Open')
          shortcut :open
          whenClicked { openImage }
        }
        quiter
      }
      menu { # gameMenu
        title tr('&Game')
        action {
          name :restart
          title tr('&Restart')
          whenClicked do         #setupPuzzle
            size = [@puzzleImage.width, @puzzleImage.height].min
            @puzzleImage = @puzzleImage.copy((@puzzleImage.width - size) / 2,
                                             (@puzzleImage.height - size) / 2, size, size).
                                        scaled(400, 400, Qt::IgnoreAspectRatio, Qt::SmoothTransformation)
            piecesList.clear
            (0...5).each do |y|
              (0...5).each do |x|
                pieceImage = @puzzleImage.copy(x * 80, y * 80, 80, 80)
                piecesList.addPiece(pieceImage, x, y) # Qt::Point.new(x, y))
              end
            end
            srand(Qt::Cursor::pos.x ^ Qt::Cursor::pos.y)
            piecesList.shuffle
            puzzleWidget.clear
          end
        }
      }
    }
    framed {
      hbox {
        pieceslist {
          name :piecesList
          dragEnabled true
          viewMode :icons
          iconSize 60
          spacing 10
          acceptDrops true
          dropIndicatorShown true
        }
        puzzlewidget {
          name :puzzleWidget
          whenCompleted do
            Qt::MessageBox::information(@qtc, tr('Puzzle Completed'),
                                        tr("Congratulations! You have completed the puzzle!\n" +
                                           "Click OK to start again."),
                                        Qt::MessageBox::Ok)
            restart.whenClicked
          end
        }
      }
    }
    sizePolicy :fixed
    windowTitle tr('Puzzle')
    openImage(File.dirname(__FILE__) + '/images/example.jpg')
  }
}