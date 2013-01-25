
require_relative '../graphicsitem'

module R::Qt
  # inconvenient 'pos' of topleft, where I expect center.
  # also GraphicsItems are NOT QGraphicsItems. Because they are QObjects...
  class GraphicsEllipseItem < AbstractGraphicsShapeItem
    public # methods of Circle_TopLeft
      attr_dynamic Rectangle, :rect 
  end 

  Reform.createInstantiator __FILE__, GraphicsEllipseItem
end

if __FILE__ == $0
  require 'reform/app'
  Reform::app {
    canvas {
      scene {
	qtcircle rect: [10, 10, 100, 100]
      }
    }
  }
end
