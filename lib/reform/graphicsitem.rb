
module Reform

  class GraphicsItem < Control
    require_relative 'graphical'
    include Graphical
  private

    # position in the Scene (not the view)
    def position x, y
      @qtc.setPos x ,y
    end

    public

    def fill brush = nil
      return @qtc.brush unless brush
      case brush
      when Qt::Brush then @qtc.brush = brush
      else @qtc.brush = color2brush(brush)
      end
    end

    alias :background :fill

    def stroke pen = nil
      return @qtc.pen unless pen
      tag "stroke #{pen.inspect}"
      @qtc.pen = case pen when Qt::Pen then pen else color2pen(pen) end
      tag "qtc.pen=#{@qtc.pen.inspect}, color.red=#{@qtc.pen.color.red}"
    end

    alias :brush :fill
    alias :pen :stroke
  end # GraphicsItem

end # Reform