
module Reform

  require_relative '../graphicsitem'

  class Circle < GraphicsItem
  private

    # override.
    def position x, y
      rect = @qtc.rect
      r, center = rect.width, rect.center
      r2 = r / 2.0
      @qtc.rect = Qt::RectF.new(x - r2, y - r2, r, r)
    end

    def radius r
      # should not change the center
      rect = @qtc.rect
      center = rect.center
#       tag "original center = #{center.inspect}"
      @qtc.rect = Qt::RectF.new(center.x - r, center.y - r, 2.0 * r, 2.0 * r)
#       tag "after radius is set to #{r}: circle.rect=#{@qtc.rect.inspect}"
    end

  public

    # KLUDGE ALERT: the rectangle argument is required, even though Qt(4.2) says it is not.
    def self.new_qt_implementor(qt_implementor_class, parent, qparent)
      circle = qt_implementor_class.new(-50.0, -50.0, 50.0, 50.0, qparent)
#       tag "parent.brush=#{parent.brush}"
      circle.pen, circle.brush = parent.pen, parent.brush
      circle
    end

  end # Circle

  createInstantiator File.basename(__FILE__, '.rb'), Qt::GraphicsEllipseItem, Circle
#   tag "test for Scene#circle"
#   raise ReformError, 'oh no' unless Scene.private_method_defined?(:circle)

end # Reform