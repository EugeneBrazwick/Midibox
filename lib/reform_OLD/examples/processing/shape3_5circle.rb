
require 'reform/app'
require 'reform/graphics/rectangle'

# TODO. Make this awesome
# Step 1: use colors
# Step 2: make the two circles rotate around each other!!

module Reform

# VERY IMPORTANT: 'count' does not work within 'struct'. So I called it depth.
  class Circle < Rectangle # ?
    private
      define_setter Float, :x, :radius
      define_setter Integer, :depth
  end  # class Circle

  class QCircle < QGraphicsRectItem     # I did it again!
    private
      def initialize p
        super
        @x, @radius, @depth = 50, 50, 4
      end

      def self.define_assigner *names
        names.each do |name|
          a = (name.to_s + '=').to_sym
          define_method a do |val|
            instance_variable_set('@' + name.to_s, val)
            update
          end
        end
      end

      def drawCircle painter, x, radius, num
        tt = (80 * num / 4.0).to_i
        b = painter.brush
        c = b.color
        c.setRgb(tt, tt, tt)
        b.color = c
        painter.brush = b
        painter.drawEllipse(x - radius, 50 - radius, radius * 2, radius * 2)
        if num > 1
          num -= 1
          radius /= 2
          drawCircle(painter, x - radius, radius, num)
          drawCircle(painter, x + radius, radius, num)
        end
      end

    public # QCircle methods

      attr :x,  :radius, :depth

      def paint painter, option, widget
        painter.brush = brush
        painter.pen = pen
        drawCircle painter, @x, @radius, @depth
      end

      define_assigner :x, :radius, :depth
  end # class QCircle

  registerKlass GraphicsItem, :rcircle, QCircle, Circle
end # Reform

Reform::app {
  form {
    struct x: 50.0, radius: 50.0, depth: 4
    hbox {
      hbox {
        [{ text: 'X', range: 10..90, connector: :x },
         { text: 'Radius', range: 5..90, connector: :radius },
         { text: 'Count', range: 1..10, connector: :depth}].each do |c|
          vbox label: { text: c[:text] },
               slider: { orientation: :vertical, range: c[:range], connector: c[:connector] }
        end
      } # hbox
      define {
        canvas_params parameters {
          area 0, 0, 100, 100
          scale 2
          background 204
        }
      }
      canvas {
        parameters :canvas_params
        rcircle {
          x connector: :x
          radius connector: :radius
          depth connector: :depth
        }
      }
    }
  }
}
