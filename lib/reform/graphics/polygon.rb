
module Reform

  require_relative '../graphicsitem'

  class Polygon < GraphicsItem
  private

    # every element should be a tuple.
    def points *pts
      poly = Qt::PolygonF.new(pts)
#       for x, y in pts do
#         poly << Qt::PointF.new(x, y)
#       end
      @qtc.polygon = poly
    end

  public

    def self.new_qt_implementor(qt_implementor_class, parent, qparent)
      poly = qt_implementor_class.new(qparent)
      poly.pen, poly.brush = parent.pen, parent.brush
      poly
    end

  end # Polygon

  createInstantiator File.basename(__FILE__, '.rb'), Qt::GraphicsPolygonItem, Polygon

end # Reform