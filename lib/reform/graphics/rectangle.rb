
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative '../graphicsitem'

  class Rectangle < GraphicsItem
  private

    def initialize parent, qtc
      super
      size 100
    end

    def size w = nil, h = nil
      return @qtc.rect.size unless w
      w, h = w if Array === w
      @qtc.setRect(@qtc.x, @qtc.y, w, h || w)
    end

    alias :geometryF :geometry

  public

    def geometry=(x, y = nil, w = nil, h = nil)
      case x
      when Qt::RectF then @qtc.setRect x
      else @qtc.setRect(Qt::RectF.new(x, y, w, h))
      end
    end

    alias :geometryF= :geometry=

  end # Rectangle

  createInstantiator File.basename(__FILE__, '.rb'), Qt::GraphicsRectItem, Rectangle

end # Reform