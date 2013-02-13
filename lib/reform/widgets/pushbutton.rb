
#  Copyright (c) 2013 Eugene Brazwick

require_relative '../abstractbutton'

module R::Qt
  # a PushButton can be connected to data in several ways.
  # it can be a toggle associated with a boolen, or a bit in a flagset.
  # it can be a one time trigger, setting a boolean or a bit to 
  # some fixed value (1 or 0).
  # This could simply be $app.quit.
  # Example:
  #
  #   Reform.app {
  #	data false
  #	button connector: :self, text: 'Push Me', value: true
  #   }
  class PushButton < AbstractButton 

    private # methods of PushButton

      def value arg = nil
	return @value unless arg
	@value = arg
      end

    public # methods of PushButton

      def apply_model data
	# ignore
      end

  end

  # req. for a plugin:
  Reform.createInstantiator __FILE__, PushButton
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

