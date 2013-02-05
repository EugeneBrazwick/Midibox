
require 'reform/app'

Reform::app {
  widget {
    size 280 * 3, 235
    grid {
      collect_names true
      columnCount 3
      define {
	par_setup parameters {
	  area 100
	  scale 2
	  background :gray
	} # parameters
      } # define
      canvas {
        use :par_setup
        line from: [20, 20], to: [80, 20]
        line from: [20, 40], to: [80, 40], stroke: { size: 6 }
        line from: [20, 70], to: [80, 70], stroke: { size: 18 }
      } # canvas
      canvas {
        use :par_setup
        w = 12
        line from: [20, 30], to: [80, 30], stroke: { weight: w, cap: :round }
        line from: [20, 50], to: [80, 50], stroke: { weight: w, cap: :flat }
        line from: [20, 70], to: [80, 70], stroke: { weight: w, cap: :project }
      } # canvas
      canvas {
        use :par_setup
        w = 12
        rect topleft: [12, 33], size: [15, 33], stroke: { weight: w, join: :bevel }
        rect topleft: [42, 33], size: [15, 33], stroke: { weight: w, join: :miter }
        rect topleft: [72, 33], size: [15, 33], stroke: { weight: w, join: :round }
      } # canvas
    } # grid
  } # widget
} # app
