
# Copyright (c) 2010 Eugene Brazwick

require 'reform/animation'

module Reform
  class AttributeAnimation < Animation

    private
      # Currently this requires that qtc is a DynamicAttribute
      def initialize parent, qtc
        super
#         tag "#{self}.new(#{parent}, #{qtc}), setting propertyName of anim to 'value'"
        @qtc.setTargetObject(parent)
        @qtc.propertyName = 'value' # See DynamicAttribute
      end

      def states stateid_value_hash
        @autostart = false
        form = containing_form
#         tag "form = #{form}, parent = #{parent}"
        dynattr = parent
        property = 'value' # dynattr.propertyname.to_s
        stateid_value_hash.each do |stateid, value|
          state = form[stateid]
          # value may very well be hacked into it....
          if Array === value
            state.qtc.assignProperty(dynattr, property, dynattr.value2variant(*value))
          else
            state.qtc.assignProperty(dynattr, property, dynattr.value2variant(value))
          end
        end
      end

      def easing v
        @qtc.easingCurve = Qt::EasingCurve::OutElastic
      end

      def startValue *value
#             tag "start, attrib=#@attrib"
        @qtc.startValue = parent.value2variant(*value)
      end

      def stopValue *value
        @qtc.endValue = parent.value2variant(*value)
      end

#       alias :startValue :start
#       alias :endValue :stop

      alias :from :startValue
      alias :to :stopValue

  end

  createInstantiator File.basename(__FILE__, '.rb'), Qt::PropertyAnimation, AttributeAnimation
end

