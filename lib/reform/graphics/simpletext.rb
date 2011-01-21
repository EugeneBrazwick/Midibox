
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative '../graphicsitem'

  # the position is once more the center
  class SimpleText < GraphicsItem
  private

    # this text can contain newlines, resulting in a multiline item (left aligned, may be based on locale?)
    def text t = nil
      return @qtc.text unless t
      @qtc.text = t
    end

    def at x, y
      @qtc.setOffset x, y
      @qtc.setTransformOriginPoint x, y
    end

  public

  end # SimpleText

  class QGraphicsSimpleTextItem < Qt::GraphicsSimpleTextItem
    private
      def initialize qparent
        super
        @pen = nil # @brush = nil
        @x = @y = 0
      end

    public

      def paint painter, option, widget
        painter.pen = @pen if @pen
#         tag "#{self}.paint, selecting font #{font.toString} for text '#{text}'"
        painter.font = font
#         painter.brush = @brush if @brush              not used
        painter.drawText(@x, @y, text)
        # super NO
        # painter.drawPath shape  NO
      end

      def setPen p
        @pen = p
        update
      end

      def pen= p
        setPen p
      end

      def setBrush b
#         @brush = b
        setPen Qt::Pen.new(b.color)
#         tag "brush:=rgb #{b.color.red},#{b.color.green},#{b.color.blue}"
        update
      end

      def brush= b
        setBrush(b)
      end

      def setOffset x, y
        @x, @y = x, y
      end

#       def setFont f
#         super
# #         tag "Installed font #{f.toString}" #, caller = #{caller.join("\n")}"
#       end

       def font= f
         setFont f
       end

  end

  createInstantiator File.basename(__FILE__, '.rb'), QGraphicsSimpleTextItem, SimpleText
#   tag "test for Scene#circle"
#   raise ReformError, 'oh no' unless Scene.private_method_defined?(:circle)

end # Reform