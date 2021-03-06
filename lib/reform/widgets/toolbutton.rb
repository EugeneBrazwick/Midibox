
#  Copyright (c) 2013 Eugene Brazwick

require_relative '_abstractbutton'

module R::Qt

  # req. for a plugin:
  Reform.createInstantiator __FILE__, ToolButton
end

if __FILE__ == $0
  require 'reform/app'
  Reform.app {
    #fail_on_errors true
    data 'blue'
    collect_names true
    widget {
      title 'Red and Blue'
      size 240, 200
      hbox {
	canvas {
	  scene {
	    qtcircle {
	      name 'gi_circle'
	      rect 10, 10, 100, 100
	      #  FAILS, since qtcircle is not a QObject.... destroyed { STDERR.puts "Errr.....??" }
	      brush name: 'br_dyn', connector: :self
	    }
	  } # scene
	} # canvas
	vbox {
	  button name: 'pb_blue', text: 'Blue', connector: :self, value: 'blue'
	  button name: 'pb_red', text: 'Red', connector: :self, value: 'red'
	  # SEGV when clicked on one, then the other.
	  # But not when pressing the same.
	} # vbox
      } # hbox
    } # widget
  } # app
end # example

