
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative 'perlin'

  # Note that 'increment' is never used here.
  class MarbledRectangle < PerlinRectangle
  private
    define_setter Float, :power, :density
  end # MarbledRectangle

  class QMarbledRectItem < QPerlinRectItem
    private
      def initialize parent
        super
        @density, @power = 8.0, 3.0
      end

    public
        #override
      def paint painter, option, widget
        require 'ruby-perlin/perlin'
        perlin = Perlin.new(@seed, @persistence, @octave, @smoothing, @contrast)
        painter.brush = Qt::Brush.new(Qt::NoBrush)
        br = boundingRect
        color = Qt::Color.new(24, 12, 12, 255) # anything (sic)
        pen = Qt::Pen.new(color)        # IMPORTANT, it seems black pens cannot change color or so.
        # We avoid instantiating thousands of colors and pens by reusing color + pen
        left, right = br.left.to_i, br.right.to_i
        d = @density.to_f # important to make sure it is a float!!
        for y in br.top.to_i..br.bottom.to_i
          for x in left..right
            total = 0.0
            i = d
            while i >= 1
              total += perlin.run(x / d, y / d) * d
              i /= 2.0
            end
            turbulence = 128.0 * total / d
            base = 0.2 * x + 0.12 * y
            offset = base + @power * turbulence / 256.0
            gray = Math.sin(offset).abs
#             tag "gray[#{x}, #{y}] = #{gray}, tot=#{total}, tur=#{turbulence}, base=#{base}, offset=#{offset}"
            color.setRgbF(gray, gray, gray, 1.0)
            pen.setColor color  # keep the weight, etc... as the user set it
            painter.pen = pen
            painter.drawRect(x, y, 1.0, 1.0)   #drawPoint looks very pale....
          end
        end
        drawSelectedRectArea(painter, br) if selected?
      end

      def power= p
        @power = p
        update
      end

      def density= d
        @density = d
        update
      end
  end

  createInstantiator File.basename(__FILE__, '.rb'), QMarbledRectItem, MarbledRectangle

end # Reform