
# This document adheres to the GNU coding standard as much as possible
# Copyright (c) 2013 Eugene Brazwick

require_relative 'widget'

module R::Qt

=begin :rdoc:

    'value' is the slider pos on exit.
    But if tracking enabled (and it is by default) it is updated
    when sliderPosition changes.

    Also setValue will always call setSliderPosition.
=end
  class AbstractSlider < Widget
    private # methods of AbstractSlider
      signal 'valueChanged(int)'

    public #methods of AbstractSlider

      # override
      def apply_model data
	#tag "#{self}.apply_model(#{data.inspect})"
	apply_dynamic_setter :value, data
      end # apply_model

      # override
      def setup hash = nil, &initblock
	super
	@mem_val = value
	if connector
	  valueChanged do |val|
	    #tag "Aha, valueChanged(#{val})"
	    push_data(@mem_val = val) unless @mem_val == val
	  end
	end # connector
      end # setup

  end

  Reform.createInstantiator __FILE__, Slider
end # module R::Qt

if __FILE__ == $0
  require 'reform/app'

  Reform::app {
    slider
  }
end
