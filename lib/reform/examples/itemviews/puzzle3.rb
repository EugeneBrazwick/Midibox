
# This only coredumps ......
# And I don't see why and where ??
# internal QListView stuff.
# it looks a better solution than puzzle2 but currently just a waste of time.

require 'reform/app'
require 'reform/widget'
require 'reform/painter'
require 'reform/model'
require 'reform/abstractlistview'

module Reform
  class QPiecesModel < Qt::AbstractListModel
    private

      def initialize parent
        super
        @pieces = []  # array of hashtuples :location, :pixmap
      end

      def addPiece pixmap, x, y
#         tag "addPiece(#{pixmap}, #{x}, #{y})"
        row = rand(2) == 1 ? 0 : @pieces.length           # at the start or at the end: 50%
        @pieces.insert(row, { pixmap: pixmap, location: Qt::Point.new(x, y) })
      end

    public

      def data index, role
#         tag "data(#{index}, #{role})"
        return Qt::Variant.new unless index.valid?
        case role
        when Qt::DecorationRole
          Qt::Variant.from_value(Qt::Icon.new(@pieces[index.row][:pixmap].scaled(60, 60, Qt::KeepAspectRatio, Qt::SmoothTransformation)))
        when Qt::UserRole
          Qt::Variant.from_value(@pieces[index.row][:pixmap])
        when Qt::UserRole + 1
          Qt::Variant.new(@pieces[index.row][:location])
        else
          Qt::Variant.new
        end
      end

      def flags index
#         tag "flags(#{index})"
        if index.valid? then Qt::ItemIsEnabled | Qt::ItemIsSelectable | Qt::ItemIsDragEnabled | Qt::ItemIsDropEnabled
        else Qt::ItemIsDropEnabled | Qt::ItemIsEnabled
        end
      end

      def removeRows row, count, parent
#         tag "removeRows(#{row}, #{count}, #{parent})"
        return false if parent.valid? || row >= @pieces.length || row + count <= 0
        beginRow = [0, row].max
        endRow = [row + count - 1, @pieces.length - 1].min
        beginRemoveRows(parent, beginRow, endRow)
        while beginRow <= endRow        # FIXME, splice ....
          @pieces.delete_at(beginRow)
          beginRow += 1
        end
        endRemoveRows
        true
      end

      def mimeTypes
#         tag "mimeTypes"
        ['image/x-puzzle-piece']                # BRACKETS MISSING === SEGV!!!!
      end

      def mimeData indexes
#         tag "mimeData(#{indexes})"
        mimeData = Qt::MimeData.new
        encodedData = Qt::ByteArray.new
        stream = Qt::DataStream.new(encodedData, Qt::IODevice::WriteOnly)
#         tag "indexes. EACH"
        indexes.each do |index|
          if index.valid?
            pixmap = data(index, Qt::UserRole)
            location = data(index, Qt::UserRole + 1).value
            stream << pixmap << location
          end
        end
        mimeData.setData('image/x-puzzle-piece', encodedData)
        mimeData
      end

      def dropMimeData data, action, row, column, parent
#         tag "dropMimeData(#{data}, #{action}, #{row}, #{column}, #{parent})"
        return false unless data.hasFormat('image/x-puzzle-piece')
        return true if action == Qt::IgnoreAction
        return false if column > 0
        if parent.valid?
          endRow = parent.row
        else
          endRow = row < 0 ? @pieces.length : [row, @pieces.length].min
        end
        encodedData = data.data('image/x-puzzle-piece')
        stream = Qt::DataStream.new(encodedData, Qt::IODevice::ReadOnly)
        until stream.atEnd
          vpixmap = Qt::Variant.new
          location = Qt::Point.new
          stream >> vpixmap >> location
          beginInsertRows(Qt::ModelIndex.new, endRow, endRow)
          @pieces.insert(endRow, { pixmap: vpixmap.value, location: location})
          endInsertRows
          endRow += 1
        end
        true
      end

      def rowCount parent = nil
#         tag "rowCount(#{parent})"
#         tag "pieces=#{@pieces.inspect}"
        if parent && parent.valid? then 0 else @pieces.length end #.tap{|v| tag "rowCount -> #{v}"}
      end

      def supportedDropActions
#         tag "supportedDropActions"
        Qt::CopyAction | Qt::MoveAction
      end

      def addPieces pixmap
#         tag "addPieces(#{pixmap})"
        beginRemoveRows(Qt::ModelIndex.new, 0, 24) # FIXME
        @pieces = []
        endRemoveRows         # FIXME
        beginInsertRows(Qt::ModelIndex.new, 0, 24)  # signals observers
        (0...5).each do |y|
          (0...5).each do |x |
#             tag "creating piece (#{x},#{y})"
            addPiece(pixmap.copy(x * 80, y * 80, 80, 80), x, y)
#             pm = Qt::Pixmap.new;
#             pm.load('examples/demos/images/bg_pattern.png')
#             tag "pm.valid=#{pm.valid?}"
#             addPiece(pm, x, y)
          end
        end
        endInsertRows # signals observers
#         tag "done addPieces"
      end
  end

#   registerKlass AbstractModel, :pieces, QPiecesModel

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
        tag "dragMoveEvent(#{event})"
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
        tag "dragMoveEvent OK"
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
          @pieces << Piece.new(pixmap.value, square, location)
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

    public
      def mousePressEvent event
        tag "mousePressEvent"
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
        tag "paintEvent"
        Painter.new(self) do |painter|
          painter.fillRect(event.rect, painter.white)
          if @highlightedRect
            painter.brush = '#ffcccc'
            painter.pen = :nopen
            painter.drawRect(@highlightedRect.adjusted(0, 0, -1, -1))
          end
          @pieces.each { |piece| painter.drawPixmap(piece.rect, piece.pixmap) }
        end
        tag "paintEvent OK"
      end

      def completed
#         tag "completed"
        @_reform_hack.whenCompleted
      end

      def clear
#         tag "#{self}#clear"
        clear_i
        update
#         tag "done Clear"
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

end

Reform::app {
  mainwindow {

#     @piecesModel = Reform::QPiecesModel.new(@qtc)
    @piecesModel = PiecesModel.new(@qtc)

    def piecesModel; @piecesModel; end

    def openImage file = nil
      unless file
        file = Qt::FileDialog::getOpenFileName(@qtc, tr('Open Image'), File.dirname(__FILE__) + '/images',
                                              tr('Images (*.png *.jpg);; All files (*.*)'))
      end
      if file && !file.empty?
        newImage = Qt::Pixmap.new
        tag "loading '#{file}'"
        unless newImage.load(file)
          Qt::MessageBox::warning(@qtc, tr('Open Image'),
                                  tr('The image file could not be loaded.'),
                                  Qt::MessageBox::Cancel)
          return
        end
        @puzzleImage = newImage
        restart.whenClicked
        tag "opened image OK"
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
            tag "setupPuzzle"
            size = [@puzzleImage.width, @puzzleImage.height].min
            tag "size = #{size.inspect}"
            @puzzleImage = @puzzleImage.copy((@puzzleImage.width - size) / 2, (@puzzleImage.height - size) / 2,
                                             size, size).
                                        scaled(400, 400, Qt::IgnoreAspectRatio, Qt::SmoothTransformation)
            oldModel = piecesList.qtc.model
            newModel = PiecesModel.new(@qtc)
            piecesList.qtc.model = newModel
            oldModel and oldModel.dispose
            srand(Qt::Cursor::pos.x ^ Qt::Cursor.pos.y)
            for y in 0...5
              for x in 0...5
                pieceImage = @puzzleImage.copy(x*80, y*80, 80, 80)
                newModel.addPiece(pieceImage, Qt::Point.new(x, y))
              end
            end

            tag "Calling clear on #{puzzleWidget}"
            puzzleWidget.clear
            tag "setupPuzzle OK"
          end
        }
      }
    }
    framed {
      hbox {
        list {
          name :piecesList
#           @qtc.setModel(containingForm.piecesModel)
          dragEnabled true
          viewMode :icons
          iconSize 60
          gridSize 80
          movement :snap
          acceptDrops true
          dropIndicatorShown true
        }
#         puzzlewidget {
#           name :puzzleWidget
#           acceptDrops true
#           fixedSize 400
#           whenCompleted do
#             Qt::MessageBox::information(@qtc, tr('Puzzle Completed'),
#                                         tr("Congratulations! You have completed the puzzle!\n" +
#                                            "Click OK to start again."),
#                                         Qt::MessageBox::Ok)
#           end
#         }
      }
    }
    sizePolicy :fixed
    sizeHint 720, 420
    windowTitle tr('Puzzle')
    tag "calling openImage"
    openImage(File.dirname(__FILE__) + '/images/example.jpg')            #             SEGV!!!
  }
}