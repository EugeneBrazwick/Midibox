
module Reform

require 'reform/graphicsitem'

  Empty = GraphicsItem

  class QEmpty < Qt::GraphicsItem
    include QGraphicsItemHackContext

    private
      def initialize parent
        super
        @pen = Qt::Pen.new
        @brush = Qt::Brush.new
      end

    public
      attr_accessor :pen, :brush

      def boundingRect
        Qt::RectF.new
      end

      def shape
        Qt::PainterPath.new
      end

      #override
      def paint painter, option, widget
      end

#       def brush= newbrush
#         oldbrush = @brush
#         newbrush = make_brush(newbrush) unless Qt::Brush === newbrush
#         return if oldbrush.equal?(newbrush)
#         @brush = newbrush
#         children.each { |child| child.brush = newbrush if child.brush.equal?(oldbrush) }
#       end
#
#       def pen= pen
#         oldpen = @pen
#         newpen = make_pen(newpen) unless Qt::Pen === newpen
#         return if oldpen.equal?(newpen)
#         @pen = newpen
#         children.each { |child| child.pen = newpen if child.pen.equal?(oldpen) }
#       end

  end

  # it should work as a container. It does not draw anything by itself. But you can set a transform
  # or a pen or brush. These then pass to the contained items.
  createInstantiator File.basename(__FILE__, '.rb'), QEmpty, Empty

end