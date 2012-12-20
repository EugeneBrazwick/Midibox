
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require 'reform/graphicsitem'

# a Point is just an ellipse with radius 0.5.
  class Point < GraphicsItem
    private
      Radius = 0.5
      Size = 2 * Radius

      def at tx, ty = nil
        tx, ty = tx if Array === tx
        @qtc.rect = Qt::RectF.new(tx - Radius, (ty || tx) - Radius, Size, Size)
      end
  end # Point

  class QPoint < Qt::GraphicsRectItem # QGraphicsRectItem      # drawing circles is slow and they do not connect properly.
    private
      def initialize parent
        super(-Point::Radius, -Point::Radius, Point::Size, Point::Size, parent)
#         super(0, 0, Point::Size, Point::Size, parent)
#            self.brush = Graphical::make_qtbrush(:black) ??
      end
    public

      def setPen pen
#         tag "change pencolor to #{pen.color}, also sets brush"
        setBrush Qt::Brush.new(pen.color)
      end

      def pen= pen
        setPen pen
      end

      def setBrush brush
        # DO NOT USE
      end

      def brush= brush
      end
  end # QPoint

  createInstantiator File.basename(__FILE__, '.rb'), QPoint, Point

end # Reform