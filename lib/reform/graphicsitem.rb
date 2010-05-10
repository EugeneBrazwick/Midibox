
module Reform

  class GraphicsItem < Control
    require_relative 'graphical'
    include Graphical
  private

    # position in the Scene (not the view)
    def position x, y
      @qtc.setPos x ,y
    end

    def fill brush
      @qtc.brush = brush
    end

    alias :background :fill

    def stroke pen
      @qtc.pen = pen
    end

  end # GraphicsItem

end # Reform