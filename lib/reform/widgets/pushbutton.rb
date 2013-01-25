
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
    data 'blue'
    widget {
      size 240, 200
      hbox {
	canvas {
	  scene {
	    qtcircle {
	      rect 10, 10, 100, 100
	      brush 'blue' #  connector: :self
	    }
	  } # scene
	} # canvas
	vbox {
	  button text: 'Blue', connector: :self, value: 'blue'
	  button text: 'Red', connector: :self, value: 'red'
	} # vbox
      } # hbox
    } # widget
  } # app
end # example

