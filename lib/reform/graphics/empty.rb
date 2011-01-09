
# Copyright (c) 2011 Eugene Brazwick

=begin
  Empty has children but no shape of its own.
  It is possible to set a pen and brush, and also a matrix(NIY)

  Difference with itemgroup: the child takes over the transform  of the parent. So
  reparenting an item in the scene to an empty will probably move it or rotate
  it etc.. An Qt::GraphicsItemGroup leaves the item where it was so there
  is no visual change.

=end
module Reform

require 'reform/graphicsitem'

  Empty = GraphicsItem

# IMPORTANT: QDuplicate inherits this but currently has a set of matrix operations
# that actually should be here! FIXME
  class QEmpty < Qt::GraphicsItem
    include QGraphicsItemHackContext

    private
      def initialize parent
        super
        @pen = Qt::Pen.new
        @brush = Qt::Brush.new
      end

    public # QEmpty methods
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

  end

  # it should work as a container. It does not draw anything by itself. But you can set a transform
  # or a pen or brush. These then pass to the contained items.
  createInstantiator File.basename(__FILE__, '.rb'), QEmpty, Empty

end