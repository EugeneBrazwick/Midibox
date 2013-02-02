
require_relative '../graphicsitem'    # required to get the GraphicsItem class complete!

Reform.createInstantiator __FILE__, R::Qt::GraphicsLineItem

if __FILE__ == $0
  require 'reform/app'
  Reform::app {
    canvas {
      size 320, 240
      scale 2.3
      scene {
	area 100
	rectangle rect: 100, stroke: :blue
	for i in 30.step(50, 10)
	  line from: [10, i], to: [90, i]
	end
      }
    }
  }
end
