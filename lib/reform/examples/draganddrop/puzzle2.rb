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

refactoring required:

1) the method drag and drop is overal handled is very similar to fridgemagnets
for example.

2) a datastructure is tore up in three different arrays, each with a separate
attribute.
In C++ classes must be expensive or what?
-> Piece class

3) some problems remain: I cannot open any files. it seems to refuse jpgs
-> the syntax is  *.png *.jpg     not    *.png, *.jpg !

4) yaml is no longer required

5) why would I store the entire image in the drag, if this is for local use
anyway? A reference to the x+y of the original image would be sufficient.
Currently the bitmap itself is actually transferred. There is no original bitmap.

=end

require 'reform/app'
require 'reform/controls/list'
require 'reform/painter'

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
        mimeData = Qt::MimeData.new # must not be deleted (as if)
        mimeData.setData('image/x-puzzle-piece', itemData)
        drag = Qt::Drag.new(self) # must not be deleted (as if)
        drag.mimeData = mimeData
        drag.hotSpot = Qt::Point.new(pixmap.width / 2, pixmap.height / 2)
        # exec returns the action performed by the acceptant, Move or Link or Copy. May be different than requested
        takeItem(row(item)) if drag.exec(Qt::MoveAction) == Qt::MoveAction
          # NOTE: deleteLater does not work on the result of takeItem? ??
      end

    public
      # we create items with 2 userdata fields using 'roles'.
      # Each piece is 1/25 of the original bitmap + coord in the range 0...5, 0...5
      def addPiece pixmap, x, y
        pieceItem = Qt::ListWidgetItem.new(self)
        pieceItem.icon = Qt::Icon.new(pixmap)
#         tag "addPiece(#{pixmap}, #{x}, #{y})"
        pieceItem.setData(Qt::UserRole, Qt::Variant::fromValue(pixmap))
        pieceItem.setData(Qt::UserRole + 1, Qt::Variant.new(Qt::Point.new(x, y)))
        pieceItem.flags = Qt::ItemIsEnabled | Qt::ItemIsSelectable | Qt::ItemIsDragEnabled
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

      class Piece
        private
          def initialize pixmap, rect, location
            @pixmap, @rect, @location = pixmap, rect, location
          end

        public
          # pixmap: piece of puzzle, rect: current rect within puzzlewidget, location: 0..4,0..4
          attr :pixmap, :rect, :location
      end

      def initialize parent
        super
        clear_i
      end

      def findPiece pieceRect
        @pieces.find_index { |item| item.rect == pieceRect }
      end

      # rectangular puzzlepiece area containing position
      def targetSquare position
        Qt::Rect.new((position.x / 80) * 80, (position.y / 80) * 80, 80, 80)
      end

      def clear_i
        @pieces = []
        # size of rectangular highlight, to show where a piece being dragged will be put
        # nil indicates 'inactive'
        @highlightedRect = nil
        # counter for nr of items that are in the correct position
        @inPlace = 0
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
        @highlightedRect = nil
        update(updateRect)
        event.accept
      end

      def dragMoveEvent event
        updateRect = (@highlightedRect || Qt::Rect.new).unite(targetSquare(event.pos))
        if event.mimeData.hasFormat('image/x-puzzle-piece') &&
          !findPiece(targetSquare(event.pos))
          @highlightedRect = targetSquare(event.pos)
          event.dropAction = Qt::MoveAction
          event.accept
        else
          @highlightedRect = nil
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
          @piece << Piece.new(pixmap.value, square, location)
          @highlightedRect = nil
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
          @highlightedRect = nil
          event.ignore
        end
      end

      def mousePressEvent event
        square = targetSquare(event.pos)
        found = findPiece(square) or return
        piece = @pieces.delete_at(found)
        location = piece.location
        @inPlace -= 1 if location.x == square.x / 80 && location.y == square.y / 80
        update square
        itemData = Qt::ByteArray.new
        dataStream = Qt::DataStream.new(itemData, Qt::IODevice::WriteOnly.to_i)
        dataStream << Qt::Variant::from_value(piece.pixmap) << location
        mimeData = Qt::MimeData.new
        mimeData.setData 'image/x-puzzle-piece', itemData
        drag = Qt::Drag.new self
        drag.mimeData = mimeData
        drag.hotSpot = event.pos - square.topLeft
        drag.pixmap = pixmap
        unless drag.exec(Qt::MoveAction) == Qt::MoveAction
          piece.square = square
          @pieces.insert(found, piece)
          update targetSquare(event.pos)
          @inPlace += 1 if location.x == square.x / 80 && location.y == square.y / 80
        end
      end

      def paintEvent event
        Painter.new(self) do |painter|
          painter.fillRect(event.rect, painter.white)
          if @highlightedRect
            painter.brush = '#ffcccc'
            painter.pen = :nopen
            painter.drawRect(@highlightedRect.adjusted(0, 0, -1, -1))
          end
          @pieces.each { |piece| painter.drawPixmap(piece.rect, piece.pixmap) }
        end
      end

    public

      def completed
        @_reform_hack.whenCompleted
      end

      def clear
        clear_i
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

    def openImage file = nil
      unless file
        file = Qt::FileDialog::getOpenFileName(@qtc, tr('Open Image'), File.dirname(__FILE__) + '/images',
                                              tr('Images (*.png *.jpg);; All files (*.*)'))
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
    end # openImage

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
                piecesList.addPiece(@puzzleImage.copy(x * 80, y * 80, 80, 80), x, y)
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
          dragEnabled true # this enabled drag AND drop in the same window, causing a reorder of items.
              # however, if I switch it off nothing happens. It still works....
#           dragEnabled false # DOES NOT WORK,
          viewMode :icons
          iconSize 60
          spacing 10
          acceptDrops true  # similar here, even if switched off it still accepts drops...
            # any dragged item will be inserted at the end...
          dropIndicatorShown true
        }
        puzzlewidget {
          name :puzzleWidget
          acceptDrops true
          fixedSize 400
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
    sizeHint 720, 420
    windowTitle tr('Puzzle')
    openImage(File.dirname(__FILE__) + '/images/example.jpg')
  }
}