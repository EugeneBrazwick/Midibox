
# Copyright (c) 2011 Eugene Brazwick

require 'reform/graphicsitem'

module Reform

  class ImageItem < GraphicsItem
    private
      def src path
        @qtc.src = path
      end

      alias :source :src

      def offset x, y
        @qtc.setOffset(x, y)
      end

      alias :at :offset

    public
      def geometry=(*value)
        value = value[0] if Array === value[0]
        @qtc.offset = Qt::PointF.new(value[0], value[1])
        @qtc.size = Qt::Size.new(value[2],  value[3] || value[2])
      end

  end

  class QGraphicsPixmapItem < Qt::GraphicsPixmapItem
    private
      def initialize qp
        super
        setTransformationMode Qt::SmoothTransformation
        @size = nil
      end

      def scalepixmap
#         tag "scalepixmap"
        (img = pixmap) && !img.null? && @size or return
        raise 'bogo' if img.null?
        # will not work with negative sizes
#         scale = [@size.width / img.width, @size.height / img.height].min
#         tag "scale img to #{@size.inspect}"
        setPixmap img.scaled(@size, Qt::KeepAspectRatio, Qt::SmoothTransformation)
        raise "Could not scale image to size #{@size.width}x#{@size.height}" if pixmap.null?
      end

    public
      def setPen p; end
      def setBrush b; end
      def pen= p; end
      def brush= b; end

      def size= sz
        @size = sz
        scalepixmap
      end

      def src= path
#         tag "src := #{path}, LOAD"
        raise "Image '#{path}' does not exist" unless File.exists?(path)
        setPixmap Qt::Pixmap.new(path)
        raise "Could not load image '#{path}'" if pixmap.null?
        scalepixmap
      end
  end # QGraphicsPixmapItem

  createInstantiator File.basename(__FILE__, '.rb'), QGraphicsPixmapItem, ImageItem
end

