
# Copyright (c) 2013 Eugene Brazwick
require 'reform/app'

Reform::app {
  widget {
    data 0
    hbox {
      canvas {
	area 100
	scale 2
	qtellipse {
	  rect 5, 5, 90, 90 
	  fill {
	    color {
	      hue connector: :self
	      saturation 255
	      value 255
	    }
	  } # fill
	} # qtellipse
      } # canvas
      slider {
	#trace_propagation true
	connector :self
	# setting an integer range makes it an integer-slider
	# the default is a 'float' slider with range 0.0 .. 1.0
	range 0..360
      } # vslider
    } # hbox
  } # widget
} # app
