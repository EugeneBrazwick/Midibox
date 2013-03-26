
require_relative '../graphicsitem'    # required to get the GraphicsItem class complete!

module R::Qt

  class GraphicsRectItem < AbstractGraphicsShapeItem
    public 
      attr_dynamic SizeF, :size
      attr_dynamic PointF, :topLeft, :topRight, :bottomLeft, :bottomRight
      attr_dynamic Float, :top, :left, :bottom, :right
      attr_dynamic RectF, :rect

      alias topleft topLeft
      alias topright topRight
      alias bottomleft bottomLeft
      alias bottomright bottomRight
      alias topleft= topLeft=
      alias topright= topRight=
      alias bottomleft= bottomLeft=
      alias bottomright= bottomRight=

  end

  Reform.createInstantiator __FILE__, GraphicsRectItem
end # module R::Qt

if __FILE__ == $0
  require 'reform/app'
  Reform::app {
    canvas {
      size 320, 240
      scene {
	area 100
	rectangle rect: [10, 10, 100, 100]
      }
    }
  }
end
