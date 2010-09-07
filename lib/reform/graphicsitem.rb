
module Reform

  class GraphicsItem < Control
    require_relative 'graphical'
    # each item can contain arbitrary children. using parentItem and childItems (Qt methods)
    include Graphical,  GraphicContext
  private

    # position in the Scene (not the view)
    def position x, y = nil
      x, y = x if y.nil?
      @qtc.setPos x ,y
    end

    public

    # override
    def addGraphicsItem control, quickyhash = nil, &block
      qc = if control.respond_to?(:qtc) then control.qtc else control end
      qc.parentItem = @qtc
      control.setup quickyhash, &block
      added control
    end

    def fill brush = nil, g = nil, b = nil, a = nil
      return @qtc.brush unless brush
      case brush
      when Qt::Brush then @qtc.brush = brush
      else @qtc.brush = color2brush(brush, g, b, a)
      end
    end

    def stroke pen = nil, g = nil, b = nil, a = nil
      return @qtc.pen unless pen
#       tag "stroke #{pen.inspect}"
      @qtc.pen = case pen when Qt::Pen then pen else color2pen(pen, g, b, a) end
#       tag "qtc.pen=#{@qtc.pen.inspect}, color.red=#{@qtc.pen.color.red}"
    end

    alias :background :fill
    alias :brush :fill
    alias :fillcolor :fill
    alias :pen :stroke

    # Important, angles less than 1.0 degree are taken to be a factor of the
    # circles length (1.0 == 360 degr = 2*pi rad)
    def rotation degrees, around_xy = nil
      degrees *= 360.0 unless Integer === degrees || degrees.abs > 1.00000001
      if around_xy
        @qtc.setTransformOriginPoint(*around_xy)
      else
        @qtc.setTransformOriginPoint(0.0, 0.0)
      end
      @qtc.rotation = degrees
    end

    def graphic?
      true
    end

    def self.contextsToUse
      GraphicContext
    end

    def addTo parent, hash, &block
      parent.addGraphicsItem self, hash, &block
    end

  end # GraphicsItem

end # Reform