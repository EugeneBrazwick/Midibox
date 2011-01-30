
require 'reform/app'
require 'reform/graphics/rectangle'

module Reform

  class Face < Rectangle
    private
      define_setter Float, :eyegap, :x, :y

    public # Face methods

  end  # class Face

  class QFace < QGraphicsRectItem
    private
      def initialize p
        super
        @x, @y = 40, 30
        @eyegap = 20
      end

    public # QFace methods

      attr :x,  :y, :eyegap

      def paint painter, option, widget
        x, y = @x, @y
        painter.brush = brush
        painter.pen = pen
        painter.drawLine(x, 0, x, y)
        painter.drawLine(x, y, x + @eyegap, y)
        painter.drawLine(x + @eyegap, y, x + @eyegap, rect.height)
        mouthY = (rect.height + y) / 2.0
        painter.drawLine(x, mouthY, x + @eyegap, mouthY)
        painter.drawEllipse(x - @eyegap / 2, y / 2, 4, 4)
        painter.drawEllipse(x + @eyegap / 2, y / 2, 4, 4)
      end

      def x= val
#         tag "x:=#{val}"
        @x = val
        update
      end

      def y= val
        @y = val
        update
      end

      def eyegap= e
        @eyegap = e
        update
      end
  end # class QFace

  registerKlass GraphicsItem, :face, QFace, Face
end # Reform

Reform::app {
  form {
    struct x: 20.0, y: 80.0, eyegap: 26.0
    hbox {
      hbox {
=begin          PROBLEMATIC.
It's obvious that using a proc as connector makes that connector read-only!
        [{ text: 'X', range: 20..70, connector: -> data { data.nosepos.x }},
         { text: 'Y', range: 30..90, connector: -> data { data.nosepos.y }},

I think I already solved it: you can pass an array of keys.
So it should be         connector: [:nosepos, :x]
That would make it possible to read and write! (I am a genius after all...)
=end
        [{ text: 'X', range: 20..50, connector: :x },
         { text: 'Y', range: 30..90, connector: :y },
         { text: 'Gap', range: 5..50, connector: :eyegap }].each do |c|
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
        face {
          eyegap connector: :eyegap
          x connector: :x
          y connector: :y
          brush white
        }
      }
    }
  }
}
