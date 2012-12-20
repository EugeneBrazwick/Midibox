
# Slightly tweaked. Strange enough the little circles seem to aline themselves...


require 'reform/app'
require 'reform/graphics/rfellipse'

module Reform

  class Circle < ReformEllipse
    private
      define_setter Integer, :depth, :seed
  end  # class Circle

  class QCircle < QReformEllipseItem
    private
      def initialize p
        super
        @depth, @seed = 4, rand(100000)
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

      def drawCircle painter, x, y, radius, num
        tt = (80 * num / 6.0).to_i
        b = painter.brush
        c = b.color
        c.setRgb(tt, tt, tt, 153)
        b.color = c
        painter.brush = b
        painter.drawEllipse(x - radius, y - radius, radius * 2, radius * 2)
        if num > 1
          num -= 1
          radius /= 2
          branches = rand(5) + 2
          branches.times do
            a = rand * Math::PI * 2
            newx = x + Math::cos(a) * 3.0 * num
            newy = y + Math::sin(a) * 3.0 * num
            drawCircle(painter, newx, newy, radius, num)
          end
        end
      end

    public # QCircle methods

      attr :depth, :seed

      def paint painter, option, widget
        srand(@seed)
        painter.brush = brush
        painter.pen = pen
        drawCircle painter, @center.x, @center.y, @radius.width / 2, @depth
      end

      define_assigner :depth, :seed
  end # class QCircle

  registerKlass GraphicsItem, :rcircle, QCircle, Circle
end # Reform

Reform::app {
  form {
    struct x: 50.0, y: 50.0, scale: 1.0, depth: 4, seed: 0
    hbox {
      hbox {
        [{ text: 'X', range: 10..90, connector: :x },
         { text: 'Y', range: 10..90, connector: :y },
         { text: 'Scale', range: [0.1, 4.0], connector: :scale },
         { text: 'Count', range: 1..6, connector: :depth}
         ].each do |c|
          vbox label: { text: c[:text] },
               slider: { orientation: :vertical, range: c[:range], connector: c[:connector] }
        end
        # setting a new seed should be a button.
        button {
          text 'New Seed'
          whenClicked { circle.seed = rand(Time.new.to_i) }
        } # button
      } # hbox
      define {
        canvas_params parameters {
          area 0, 0, 100, 100
          scale 4
          background 204
        }
      }
      canvas {
        parameters :canvas_params
        pen :none
        rcircle {
          name :circle
          scale connector: :scale
          translation -> data { Qt::PointF.new(data.x, data.y) }
          depth connector: :depth
        }
      } # canvas
    }
  }
}
