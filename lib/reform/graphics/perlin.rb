
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative 'rectangle'

  class PerlinRectangle < Rectangle
  private

    define_setter Float, :increment, :persistence, :contrast
    define_setter Integer, :seed, :octave
    define_setter Boolean, :smoothing

  public

  end # PerlinRectangle

  class QPerlinRectItem < QGraphicsRectItem
    private
      def initialize parent
        super
        @increment = 0.05
        @persistence, @smoothing, @octave = 1.0, false, 1
        @contrast = 1.0
        @seed = 1
      end

    public
        #override
      def paint painter, option, widget
        require 'ruby-perlin/perlin'
        perlin = Perlin.new(@seed, @persistence, @octave, @smoothing, @contrast)
        painter.brush = Qt::Brush.new(Qt::NoBrush)
        br = boundingRect
        ynoise = 0.0
        color = Qt::Color.new(24, 12, 12, 255) # anything (sic)
        pen = Qt::Pen.new(color)        # IMPORTANT, it seems black pens cannot change color or so.
        # We avoid instantiating thousands of colors and pens by reusing color + pen
        left, right = br.left.to_i, br.right.to_i
        for j in br.top.to_i..br.bottom.to_i
          xnoise = 0.0
          for i in left..right
            gray = perlin.run(xnoise, ynoise)
#             tag "[#{i},#{j}] (#{xnoise},#{ynoise}) := #{gray}"
            color.setRgbF(gray, gray, gray, 1.0)
            pen.setColor color  # keep the weight, etc... as the user set it
             # it does NOTHING!!!!
#             tag "color = #{color.red}, #{color.green}, #{color.blue}"
#             tag "pen.color = #{pen.color.red}, #{pen.color.green}, #{pen.color.blue}"
            painter.pen = pen
            painter.drawRect(i, j, 1.0, 1.0)   #drawPoint looks very pale....
            xnoise += @increment
          end
          ynoise += @increment
        end
        drawSelectedRectArea(painter, br) if selected?   # does not work -> (option.state & Qt::Style::State_Selected) != 0
      end

      def increment= v
        @increment = v
        update
      end

      def seed= v
        @seed = v
        update
      end

      def persistence= v
        @persistence = v
        update
      end

      def smoothing= v
        @smoothing = v
        update
      end

      def octave= v
        @octave = v
        update
      end

      def contrast= v
        @contrast = v
        update
      end
  end

  createInstantiator File.basename(__FILE__, '.rb'), QPerlinRectItem, PerlinRectangle

end # Reform