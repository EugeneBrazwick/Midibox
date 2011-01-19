
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative '../graphicsitem'

  # the position is once more the center
  class GraphicText < GraphicsItem
    private

      def text t = nil
        return @qtc.plainText unless t
        @qtc.plainText = t
      end

      def html t = nil
        return @qtc.html unless t
        @qtc.html = t
      end

      def textWidth w = nil
        return @qtc.textWidth unless w
        @qtc.textWidth = w
      end

      alias :width :textWidth

      def at x, y
        @qtc.pos = Qt::PointF.new(x, y)
      end

      def geometry x = nil, y = nil, w = nil, h = nil, &block
        return @qtc.geometry unless x || w || block
        case x
        when nil then DynamicAttribute.new(self, :geometryF, Qt::RectF).setup(nil, &block)
        when Hash, Proc then DynamicAttribute.new(self, :geometryF, Qt::RectF).setup(x, &block)
        else
          @qtc.pos = Qt::PointF.new(x, y)
          @qtc.width = w
        end
      end

#       def text= text
#         @qtc.plainText = text
#       end

  end # GraphicText

  class QGraphicsTextItem < Qt::GraphicsTextItem
    include QGraphicsItemHackContext
    public
      def setPen p
        setDefaultTextColor(p.color)
        update
      end

      def pen= p
        setPen p
      end

      def setBrush b
        setDefaultTextColor(b.color)
        update
      end

      def brush= b
        setBrush(b)
      end

  end # class QGraphicsTextItem

  createInstantiator File.basename(__FILE__, '.rb'), QGraphicsTextItem, GraphicText

end # Reform