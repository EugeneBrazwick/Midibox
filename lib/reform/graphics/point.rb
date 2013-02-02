
require_relative '../graphicsitem'    # required to get the GraphicsItem class complete!

Reform.createInstantiator __FILE__, R::Qt::GraphicsPointItem

if __FILE__ == $0
  require 'reform/app'
  Reform::app {
    canvas {
      size 320, 240
      scale 2.3
      scene {
	# 'area' icw scale causes the scene to have a fixed size
	area 100
	rectangle rect: 100, stroke: :blue
	def pts *xs 
	  for x in xs
	    point pos: [x, x]
	  end
	end
	pts 20, 30, 40, 50, 60
      }
    }
  }
end
