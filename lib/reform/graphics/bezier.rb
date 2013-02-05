
require_relative '../graphicsitem'

Reform.createInstantiator __FILE__, R::Qt::BezierCurve

if __FILE__ == $0
  require 'reform/app'
  Reform::app {
    canvas {
      size 320, 240
      scale 2.2
      scene {
	area 100
	background :lightGray
	bezier {
	  from 32, 20
	  c1 80, 5
	  c2 80, 75
	  to 30, 75
	  fill :red
	}
      }
    }
  }
end
