
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative '../graphicsitem'

  # the position is once more the center
  class Rectangle < GraphicsItem
  private

    def size w = nil, h = nil
      return @qtc.rect.size unless w
      w, h = w if Array === w
      @qtc.setRect(@qtc.x, @qtc.y, w, h || w)
    end

  public

  end # Rectangle

  createInstantiator File.basename(__FILE__, '.rb'), Qt::GraphicsRectItem, Rectangle

end # Reform