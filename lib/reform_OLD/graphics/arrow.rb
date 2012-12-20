
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative 'line'

  class Arrow < Line
    private
#       def initialize parent, qtc
#         super
#       end

#       define_dynamic_setters Float, :arrowLength, :arrowPhi   # maybe later

      define_simple_setters :arrowLength, :arrowPhi

  end # class Arrow

  class QGraphicsArrowItem < QGraphicsLineItem
    private
      def initialize parent
        super
        @arrowLength = 16.0
        @arrowPhi = 30 # degrees, 0.3 * 360.0 / Math::PI / 4.0
        reconstruct
      end

      def reconstruct
        childItems.each { |i| i.parentItem = nil }
        childItems.length == 0 or raise 'errrrr'
        l = line
        phi = @arrowPhi / 90.0 * Math::PI * 4;
        psi = Math::asin(l.dx / Math::hypot(l.dx, l.dy)
        psi = l.y2 > l.y1 ? psi : Math::PI - psi;
        x = l.x2 - @arrowLength * Math::sin(psi - phi)
        y = l.y2 - @arrowLength * Math::cos(psi - phi)
        Qt::GraphicsLineItem.new(l.x2, l.y2, x, y, self)
        x = l.x2 - @arrowLength * Math::sin(psi + phi)
        y = l.y2 - @arrowLength * Math::cos(psi + phi)
        Qt::GraphicsLineItem.new(l.x2, l.y2, x, y, self)
      end

    public
#       def paintEvent ev
#         super
#       end

      # length of the two arrow head lines
      def arrowLength= val
        @arrowLength = val
#         update
        reconstruct
      end

      # angle of the two head lines with main arrow line, in degrees
      def arrowPhi= val
        @arrowPhi= val
        reconstruct
#         @qtc.update
      end

  end

  createInstantiator File.basename(__FILE__, '.rb'), QGraphicsArrowItem, Arrow
#   tag "test for Scene#circle"
#   raise ReformError, 'oh no' unless Scene.private_method_defined?(:circle)

end # Reform