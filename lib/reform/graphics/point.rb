
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require 'reform/graphicsitem'

# a Point is just a line of length 0
  class Point < GraphicsItem
    private
  end # Point

# Not going to work...  A line with length 0 is always invisible,
# Ellipse is also ugly as it there should be an automatic fill.
#   class QGraphicsPointItem < Qt::GraphicsLineItem
  class QGraphicsPointItem < Qt::GraphicsEllipseItem
    include QGraphicsItemHackContext
    private
      def initialize parent
        super 0.0, 0.0, 1.0, 1.0, parent
      end
    public
      # override
      def paint painter, option, widget = nil
        painter.brush = Qt::Brush.new(Qt::Color.new(painter.pen.color))
        painter.drawEllipse(Qt::PointF.new(0.0, 0.0), 0.5, 0.5)
      end
  end

  createInstantiator File.basename(__FILE__, '.rb'), QGraphicsPointItem, Point

end # Reform