
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative '../graphicsitem'

  class Rectangle < GraphicsItem
  private

    def initialize parent, qtc
      super
#       tag "creating #{self} with parent #{parent}"
      size 100
    end

    def size w = nil, h = nil
      return @qtc.rect.size unless w
      w, h = w if Array === w
      # for some reason rect.x is anything except x!
      @qtc.setRect(@qtc.rect.x, @qtc.rect.y, w, h || w)
    end

    alias :geometryF :geometry

    def topleft x, y = nil
      x, y = x if Array === x
#       tag "calling setRect(#{x}, #{y}, #{@qtc.rect.width}, #{@qtc.rect.height})"
      @qtc.setRect(x, y, @qtc.rect.width, @qtc.rect.height)
    end

    # should follow 'topleft'
    def bottomright x, y = nil
      x, y = x if Array === x
      r = @qtc.rect
      rx, ry = r.x, r.y
      @qtc.setRect(rx, ry, x - rx, y - ry)
    end

  public

    def geometry=(x, y = nil, w = nil, h = nil)
#       tag "geo=(#{x.inspect}, #{y}, #{w}, #{h})"
      case x
      when Array
        x[3] ||= x[2]
#         tag "Qt::RectF.new(x = #{x.inspect})"
        @qtc.rect = Qt::RectF.new(*x)
      when Qt::RectF then @qtc.setRect x
      else @qtc.setRect(Qt::RectF.new(x, y, w, h || w))
      end
    end

    alias :geometryF= :geometry=

  end # Rectangle

  createInstantiator File.basename(__FILE__, '.rb'), Qt::GraphicsRectItem, Rectangle

end # Reform