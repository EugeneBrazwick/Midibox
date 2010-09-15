
module Reform

  require 'reform/graphicsitem'

# Basicly this is just the same as a single grouping item.
  class Transform < GraphicsItem
  private
#     def initialize parent, qtc
#       super
#       @translate = @rotate = @scale = nil
#     end

  public
    def boundingRect
      tag "#{self}.boundingRect"
      b = Qt::RectF.new
      childItems.each { |i| b |= i.boundingRect }
      b
    end

    #override
    def opaqueArea
      tag "#{self}.opaqueArea"
      o = Qt::PainterPath.new
      childItems.each { |i| o |= i.opaqueArea }
      o
    end

    def paint painter, option, widget = nil
      tag "#{self}.painter"
      childItems.each do |i|
        i.paint(painter, option, widget)
      end
    end

  end # Transform

  createInstantiator File.basename(__FILE__, '.rb'), Qt::GraphicsItem, Transform

end # Reform