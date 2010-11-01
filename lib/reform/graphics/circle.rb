
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require 'reform/graphicsitem'

# tag "LOADING Circle class"

# the default pos is 0,0 and the width 100
  class Circle < GraphicsItem
    private

      def width w = nil
        return @qtc.rect.width unless w
        # should not change the center
        @qtc.rect = Qt::RectF.new(@qtc.x, @qtc.y, w, w)
      end

      alias :size :width

    public

      # KLUDGE ALERT: the rectangle argument is required, even though Qt(4.2) says it is not.
      def self.new_qt_implementor(qt_implementor_class, parent, qparent)
  #       tag "new_qt_implementor(#{qt_implementor_class}, #{parent}, #{qparent})"
        circle = qt_implementor_class.new(0, 0, 100.0, 100.0, qparent)
  #       tag "created circle #{circle}"
  #       tag "parent=#{parent}"
  #       tag "parent.brush=#{parent.brush}, pen=#{parent.pen.inspect}"
  #       tag "caller=#{caller.join("\n")}"
        circle.pen, circle.brush = parent.pen, parent.brush
        circle
      end

  end # Circle

  class QGraphicsEllipseItem < Qt::GraphicsEllipseItem
    include QGraphicsItemHackContext
  end

  createInstantiator File.basename(__FILE__, '.rb'), QGraphicsEllipseItem, Circle
#   tag "test for Scene#circle"
#   raise ReformError, 'oh no' unless Scene.private_method_defined?(:circle)

end # Reform