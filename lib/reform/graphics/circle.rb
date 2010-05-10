
module Reform

  require_relative '../graphicsitem'

  class Circle < GraphicsItem
  private

    def radius r
      rect = @qtc.rect
      rect.width = rect.height = 2.0 * r
      @qtc.rect = rect
    end

  public

    # KLUDGE ALERT: the rectangle argument is required, even though Qt says it is not.
    def self.new_qt_implementor(qt_implementor_class, parent)
      # q =
      qt_implementor_class.new(0.0, 0.0, 100.0, 100.0)
#       q.brush = defaultBrush
#       q
    end

  end # Circle

  createInstantiator File.basename(__FILE__, '.rb'), Qt::GraphicsEllipseItem, Circle

end # Reform