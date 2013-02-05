
require_relative '../graphicsitem'

Reform.createInstantiator __FILE__, R::Qt::GraphicsTriangleItem

if __FILE__ == $0
  require 'reform/app'
  Reform::app {
    canvas {
      size 320, 240
      scene {
	area 100
	background :lightGray
	triangle {
	  points [60, 10], [25, 60], [75, 65]
	  fill :white
	}
	line from: [60, 30], to: [25, 80]
	line from: [25, 80], to: [75, 85]
	line from: [75, 85], to: [60, 30]
      }
    }
  }
end
