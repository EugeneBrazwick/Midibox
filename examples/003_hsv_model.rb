
# Copyright (c) 2013 Eugene Brazwick

# you can run this program from anywhere using 
# RUBYLIB=<installpath>/Midibox/lib ruby <installpath>/Midibox/examples/003_hsv_model.rb

require 'reform/app'

Reform::app {
  widget {
    # 'model', an integer representing 'hue'.
    data 0
    # horizontal layout:
    hbox {
      # canvas = graphicsview. These are aliases btw.
      canvas {
	# 'virtual' mapping so coords are from 0..100 no matter the window size
	# it seems that this tweaks the sizeHint but that's OK
	area 100
	# apply a matrix
	scale 2
	# it will create an internal scene, if not otherwise specfied.
	# qtellipse is kind of ugly since it use tlrb and not radius + center.
	qtellipse {
	  rect 5, 5, 90, 90 
	  # 'fill' is an alias for 'brush'
	  fill {
	    color {
	      # connect the hue to the 'data'. And the only thing there is is data.self
	      hue connector: :self
	      saturation 255
	      value 255
	    }
	  } # fill
	} # qtellipse
      } # canvas
      slider {
	# orientation :vertical	  # this is the default.
	# setting an integer range makes it an integer-slider
	# the default is a 'float' slider with range 0.0 .. 1.0
	range 0..360
	# trace_propagation true  # use this to see data pushing in action
	# same as qtellipse.fill.color.hue. So now moving the slider changes 'data'
	# which in turn will change the qtellipse brush-color
	connector :self
      } # slider
    } # hbox
  } # widget
} # app
