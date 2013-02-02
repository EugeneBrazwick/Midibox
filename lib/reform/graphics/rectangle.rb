
require_relative '../graphicsitem'    # required to get the GraphicsItem class complete!

Reform.createInstantiator __FILE__, R::Qt::GraphicsRectItem

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
