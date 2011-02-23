
# Copyright (c) 2010 Eugene Brazwick

require 'reform/animation'

module Reform
  class AttributeAnimation < Animation

    private
      # Currently this requires that qtc is a DynamicAttribute
      def initialize parent, qtc
        super
#         tag "#{self}.new(#{parent}, #{qtc}), setting propertyName of anim to 'value'"
        @qtc.setTargetObject(dynamicParent)
#         tag "TargetObject = #{@qtc.targetObject}"
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

      # it seems to me that easing should be set per statevalue. And Qt uses the trajectory
      # between states...
      EasingMap = { linear: Qt::EasingCurve::Linear,
                    quad: Qt::EasingCurve::InOutQuad,
                    cubic: Qt::EasingCurve::InOutCubic,
                    sine: Qt::EasingCurve::InOutSine,
                    elastic: Qt::EasingCurve::OutElastic,
                    back: Qt::EasingCurve::OutBack,
                    overshoot: Qt::EasingCurve::OutBack,
                    bounce: Qt::EasingCurve::OutBounce,
                    accelerate: Qt::EasingCurve::InCubic,
                    accelerate2: Qt::EasingCurve::InQuad,
                    accelerate3: Qt::EasingCurve::InCubic,
                    accelerate4: Qt::EasingCurve::InQuart,
                    accelerate5: Qt::EasingCurve::InQuint,
                    accelerateEx: Qt::EasingCurve::InExpo,
                    slowdown: Qt::EasingCurve::OutCubic,
                    slowdown2: Qt::EasingCurve::OutQuad,
                    slowdown3: Qt::EasingCurve::OutCubic,
                    slowdown4: Qt::EasingCurve::OutQuart,
                    slowdown5: Qt::EasingCurve::OutQuint,
                    slowdownEx: Qt::EasingCurve::OutExpo,
                    }

      # this could be expanded using class EasingCurve < Control
      # if v is a Hash or Proc or a block is passed
      def easing v
        @qtc.easingCurve = case v
        when Qt::EasingCurve then v
        when Symbol then Qt::EasingCurve.new(EasingMap[v] || Qt::EasingCurve::Linear)
        else Qt::EasingCurve.new(v)
        end
      end

      def startValue *value
#         tag "start, attrib=#@attrib, value=#{value.inspect}"
        @qtc.startValue = @qtc.targetObject.value2variant(*value)
      end

      def stopValue *value
        @qtc.endValue = @qtc.targetObject.value2variant(*value)
      end

      # pass an array or hash.
      # if an array the values are set on equadistant points.
      # The  array should be at least 2 long (being start and stop)
      # If a hash is passed the keys must be floats in range 0.0 to 1.0
      #
      # due to limitations in qtruby stops do not replace. They always add, so to alter the values
      # you must create a new animation instead...
      def values *value
        hash = nil
        dparent = @qtc.targetObject # same as 'dynamicParent'
        if value.length == 1
          case v = value[0]
          when Hash
            v.each { |key, val| @qtc.setKeyValueAt(key, dparent.value2variant(val)) }
            return
          when Array then value = v
          end
        end
        d = 1.0 / (value.length - 1)
        t = 0.0
        value.each do |val|
          @qtc.setKeyValueAt(t, dparent.value2variant(val))
          t += d
        end
      end

#       alias :startValue :start
#       alias :endValue :stop

      alias :from :startValue
      alias :to :stopValue

  end

  class QPropertyAnimation < Qt::PropertyAnimation
    include QAnimationHackContext
#     def initialize parent
#       super
#       tag "QPropertyAnimation is created, has method 'finished'"
#     end
#     signals 'finished()', 'stateChanged(QAnimation::State newState, QAnimation::State oldState)'
  end

  createInstantiator File.basename(__FILE__, '.rb'), QPropertyAnimation, AttributeAnimation
end

