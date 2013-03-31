
#  Copyright (c) 2013 Eugene Brazwick

require_relative '_abstract_animation'

module R::Qt

  class VariantAnimation < AbstractAnimation
    public # methods of VariantAnimation

      def easingCurve *args, &block
	if args[0] || block
	  EasingCurve.new self, *args, &block
	else
	  easingCurve_get
	end
      end

      alias from startValue
      alias to endValue
      alias easing easingCurve

  end # class VariantAnimation
  Reform.createInstantiator __FILE__, PropertyAnimation
end
