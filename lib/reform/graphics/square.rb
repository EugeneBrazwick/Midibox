
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative '../graphicsitem'

  # the position is once more the center
  class Square < GraphicsItem
  private

    def width w = nil
      return @qtc.rect.width unless w
      @qtc.setRect(@qtc.x, @qtc.y, w, w)
    end

  public

  end # Square

  createInstantiator File.basename(__FILE__, '.rb'), Qt::GraphicsRectItem, Square
#   tag "test for Scene#circle"
#   raise ReformError, 'oh no' unless Scene.private_method_defined?(:circle)

end # Reform