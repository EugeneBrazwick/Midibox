
require_relative 'dynamic_attr'

module R::Qt
  class DynamicColor < DynamicAttribute
      attr_dynamic Fixnum, :hue, :saturation, :value, 
			   :red, :green, :blue, :alpha,
			   :cyan, :magenta, :yellow, with_acceptors: true
      attr_dynamic Float, :hueF, :saturationF, :valueF, 
			  :redF, :greenF, :blueF, :alphaF,
			  :cyanF, :magentaF, :yellowF, with_acceptors: true
  end # class DynamicColor
end # module R::Qt

