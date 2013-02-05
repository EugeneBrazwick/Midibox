
require_relative '../graphicsitem'

Reform.createInstantiator __FILE__, R::Qt::GraphicsPolygonItem

if __FILE__ == $0
  require 'reform/app'
  Reform::app {
    canvas {
      size 320, 240
      scene {
	area 100
      }
    }
  }
end
