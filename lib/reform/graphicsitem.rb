
# Copyright (c) 2010 Eugene Brazwick

module Reform

  class GraphicsItem < Control
    require_relative 'graphical'
    # each item can contain arbitrary children. using parentItem and childItems (Qt methods)
    include Graphical,  GraphicContext
    private

      # position in the Scene (not the view)
      def position tx = nil, ty = nil
        return @qtc.pos unless tx
        tx, ty = tx if Array === tx
        @qtc.setPos(tx, ty || tx)
      end

      alias :translate :position

      def movable onoff = nil, &block
        case onoff
        when Hash, Proc then DynamicAttribute.new(self, :movable, TrueClass, onoff, &block)
        else @qtc.setFlag Qt::GraphicsItem::ItemIsMovable, onoff
        end
      end

      define_simple_setter :zValue

      # NOTE: this is 'fat'. Not every GraphicsItem has a geometry.
      def geometry x = nil, y = nil, w = nil, h = nil, &block
        return @qtc.geometry unless x || w || block
        case x
        when nil then DynamicAttribute.new(self, :geometryF, Qt::RectF).setup(nil, &block)
        when Hash, Proc then DynamicAttribute.new(self, :geometryF, Qt::RectF).setup(x, &block)
        else self.geometry = x, y, w, h
        end
      end

    public

      def movable= onoff
        @qtc.setFlag Qt::GraphicsItem::ItemIsMovable, onoff
      end

      # override, graphic items may be nested
      def addGraphicsItem control, quickyhash = nil, &block
        qc = if control.respond_to?(:qtc) then control.qtc else control end
        qc.parentItem = @qtc
        control.setup quickyhash, &block
        added control
      end

      def fill brush = nil, g = nil, b = nil, a = nil, &block
  #       tag "fill(#{brush}, #{g}, #{b}, #{a})"
        return @qtc.brush unless brush || block
        case brush
        when Symbol then @qtc.brush = frame_ex.registeredBrush(brush) || make_brush(brush, g, b, a)
        when Hash, Proc then DynamicAttribute.new(self, :brush, Qt::Brush).setup(brush, &block)
        when Qt::Brush then @qtc.brush = brush
        when nil then DynamicAttribute.new(self, :brush, Qt::Brush).setup(&block)
        else @qtc.brush = make_brush(brush, g, b, a)
        end
      end

      def stroke pen = nil, g = nil, b = nil, a = nil, &block
        return @qtc.pen unless pen || block
        case pen
        when Symbol then @qtc.pen = frame_ex.registeredPen(pen) || make_pen(pen, g, b, a)
        when Hash, Proc
          tag "#{self}::stroke + Hash/Proc -> DynamicAttribute"
          DynamicAttribute.new(self, :pen, Qt::Pen, pen, &block)
        when Qt::Pen then @qtc.pen = pen
        when nil then Pen.new(self).setup(&block)
        else
  #       tag "stroke #{pen.inspect}"
          @qtc.pen = make_pen(pen, g, b, a)
        end
  #       tag "qtc.pen=#{@qtc.pen.inspect}, color.red=#{@qtc.pen.color.red}"
      end

      alias :background :fill
      alias :brush :fill
      alias :fillcolor :fill
      alias :pen :stroke

      # Important, angles less than 1.0 degree are taken to be a factor of the
      # circles length (1.0 == 360 degr = 2*pi rad)
      def rotation degrees_cw, around_xy = nil
        degrees_cw *= 360.0 unless Integer === degrees_cw || degrees_cw.abs > 1.00000001
        if around_xy
          @qtc.setTransformOriginPoint(*around_xy)
        else
          @qtc.setTransformOriginPoint(0.0, 0.0)
        end
        @qtc.rotation = degrees_cw
      end

=begin EVIL
      # this uses Eugene circle units where 1.0 == 360 degrees.
      # except when degrees_ccw is an int or larger than 1
      def rotate degrees_ccw, around_xy = nil
        degrees *= 360.0 unless Integer === degrees || degrees.abs > 1.00000001
        if around_xy
          @qtc.setTransformOriginPoint(*around_xy)
        else
          @qtc.setTransformOriginPoint(0.0, 0.0)
        end
        @qtc.rotation += degrees
      end
=end

      def scale sx, sy = nil
        sx, sy = sx if Array === sx
        raise "scaling in two dimensions is not currently supported" if sy
        @qtc.scale = sx
      end

#       def graphic?
#         true
#       end

#       def self.contextsToUse
#         GraphicContext
#       end

      def addTo parent, hash, &block
        parent.addGraphicsItem self, hash, &block
      end

      def brush= brush
        @qtc.brush = case brush when Qt::Brush then brush else make_brush(brush) end
      end

      def pen= pen
        @qtc.pen = case pen when Qt::Pen then pen else make_pen(pen) end
      end

      def geometry=(*value)  # this is quick 'n dirty.  FIXME
        @qtc.pos = Qt::Point.new(value[0], value[1])
        self.size  = Qt::Size.new(value[2],  value[3])
      end

  end # GraphicsItem

end # Reform