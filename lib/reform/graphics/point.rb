
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative 'qtcircle'

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

  class QPoint < QGraphicsEllipseItem
    private
      def initialize parent
        super(-Point::Radius, -Point::Radius, Point::Size, Point::Size, parent)
#            self.brush = Graphical::make_qtbrush(:black) ??
      end
  end # QPoint

  createInstantiator File.basename(__FILE__, '.rb'), QPoint, Point

end # Reform