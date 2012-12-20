
# Copyright (c) 2010-2011 Eugene Brazwick

module Reform

  require 'reform/graphicsitem'

# tag "LOADING Circle class"

# the default pos is 0,0 and the width 100
  class Circle < GraphicsItem
    private

      def topleft tx = nil, ty = nil
        return @qtc.rect.topLeft unless tx
        tx, ty = tx if Array === tx
#         tag "qtc.setPos := #{tx}, #{ty}, rect = #{@qtc.rect.inspect}"
        @qtc.rect = Qt::RectF.new(tx, ty || tx, @qtc.rect.width, @qtc.rect.width)
      end

      def width w = nil
        return @qtc.rect.width unless w
#         tag "width:=#{w}, qtc.rect := #{@qtc.x}, #{@qtc.y}, #{w}, #{w}"
        @qtc.rect = Qt::RectF.new(@qtc.rect.x, @qtc.rect.y, w, w)
      end

      alias :size :width

      def radius w = nil
        return @qtc.rect.width / 2.0 unless w
        @qtc.rect = Qt::RectF.new(@qtc.rect.x, @qtc.rect.y, 2.0 * w, 2.0 * w)
      end

    public

      # override BAD default....
      def geometry=(*value)  # this is quick 'n dirty.  FIXME
        @qtc.rect = Qt::RectF.new(value[0], value[1], value[2],  value[3])
      end

      # KLUDGE ALERT: the rectangle argument is required, even though Qt(4.2) says it is not.
      def self.new_qt_implementor(qt_implementor_class, parent, qparent)
  #       tag "new_qt_implementor(#{qt_implementor_class}, #{parent}, #{qparent})"
        qt_implementor_class.new(0, 0, 100.0, 100.0, qparent)
  #       tag "created circle #{circle}"
  #       tag "parent=#{parent}"
  #       tag "parent.brush=#{parent.brush}, pen=#{parent.pen.inspect}"
  #       tag "caller=#{caller.join("\n")}"
#         circle.pen, circle.brush = parent.pen, parent.brush
#         circle
      end

  end # Circle

  class QGraphicsEllipseItem < Qt::GraphicsEllipseItem
    include QGraphicsItemHackContext
  end

  createInstantiator File.basename(__FILE__, '.rb'), QGraphicsEllipseItem, Circle
#   tag "test for Scene#circle"
#   raise ReformError, 'oh no' unless Scene.private_method_defined?(:circle)

end # Reform