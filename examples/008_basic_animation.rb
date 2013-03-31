
# Copyright (c) 2013 Eugene Brazwick

# you can run this program from anywhere using 
# RUBYLIB=<installpath>/Midibox/lib ruby <installpath>/Midibox/examples/008_basic_animation.rb

require 'reform/app'

Reform::app {
  fail_on_errors true
  canvas {
    area 200
    scale 2
    qtellipse {
      rect 5, 5, 190, 190
      fill.color {
	# animation is 'property_animation'
	# 'from' is an alias for 'startValue' and 'to' is the same as 'endValue'.
	# It is not possible to say 'hue.animation from: .... '
	# Since 'fill.color.hue()' just returns an integer after all(!)
	hue {
	  animation {
	    from 0
	    to 360 
	    duration 5_000  # milliseconds
	    #tag "connecting 'finished' signal to app.quit"
	    finished { $app.quit }
	  }
	} # hue
	saturation 255
	value 255
      } # fill.color
    } # qtellipse
  } # canvas
} # app
