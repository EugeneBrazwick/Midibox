
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
	apply_dynamic_setter(if @floatmode then :valueF else :value end, data)
      end # apply_model

      # override
      def setup hash = nil, &initblock
	super
	@mem_val = value
	if connector
	  valueChanged do |val|
	    #tag "Aha, valueChanged(#{val.inspect})"
	    unless @mem_val == val
	      @mem_val = val  # still an int
	      val /= FloatModeFactor if @floatmode
	      push_data val
	    end
	  end
	end # connector
      end # setup
  
      attr_dynamic Fixnum, :value, :minimum, :maximum
      attr_dynamic Symbol, :orientation
      attr_dynamic Float, :minimumF, :maximumF, :valueF

      # shouldn't there be a valueF ??
  end  #class AbstractSlider

  class Slider < AbstractSlider
    public # methods of Slider
      attr_dynamic Symbol, :tickPosition
      attr_dynamic Fixnum, :tickInterval
  end # class Slider
  Reform.createInstantiator __FILE__, Slider
end # module R::Qt

if __FILE__ == $0
  require 'reform/app'

  Reform::app {
    slider
  }
end
