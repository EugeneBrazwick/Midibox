
# Copyright (c) 2011 Eugene Brazwick

module Reform

  require_relative '../graphicsitem'

  class Quad < GraphicsItem
    private # Quad methods

      # pass (an array of) 4 points (or 2 reals), or 8 reals
      def points *pts
        pts = pts[0] if pts.length == 1
        case pts.length
        when 4
        when 8
          pts = [Qt::PointF.new(pts[0], pts[1]),
                    Qt::PointF.new(pts[2], pts[3]),
                    Qt::PointF.new(pts[4], pts[5]),
                    Qt::PointF.new(pts[6], pts[7])]
        else
          raise 'bad quad count'
        end
        pts[5] = pts[0]
#         tag "new PolygonF(#{pts.inspect})"
        @qtc.polygon = Qt::PolygonF.new(pts)
      end

    public # Quad methods
#       def self.new_qt_implementor(qt_implementor_class, parent, qparent)
#         t = qt_implementor_class.new(qparent)
# #         tag "parent.brush = #{parent.brush.inspect}"
#         t.pen, t.brush = parent.pen, parent.brush
#         t
#       end

  end # Quad

  createInstantiator File.basename(__FILE__, '.rb'), Qt::GraphicsPolygonItem, Quad

end # Reform