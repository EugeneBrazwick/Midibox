
# Copyright (c) 2011 Eugene Brazwick

module Reform

  require_relative 'widget'

  class Slider < Widget
    private

      FloatModeFactor = 1000.0

      def initialize parent, qtc
        super
        @floatmode = false
        # I expect that changing the slider by even a little should have effect immediately
        # Otherwise another kind of control should be used.
        connect(@qtc, SIGNAL('valueChanged(int)'), self) do |value|
          rfRescue do
#             tag "#{self}::valueChanged in #{value}, track_propagation = #{track_propagation}"
            if (mod = model) && (cid = connector)
#               tag "APPLY_SETTER, value = #{value}"
              model.model_apply_setter(cid, @floatmode ? value / FloatModeFactor : value, self)
            end
          end
        end
      end

      # note this resembles SpinBox a lot
      def range m, n = nil
        @floatmode = false
        if n
          if Float === n
            @floatmode = true
#             tag "setRange(#{FloatModeFactor * m}, #{FloatModeFactor * n})"
            @qtc.setRange(FloatModeFactor * m, FloatModeFactor * n)
          else
            @qtc.setRange(m, n)
          end
        else
          if Range === m
            @qtc.setRange(m.min, m.max)
          else
            if Float === m[0]
              @floatmode = true
              @qtc.setRange(FloatModeFactor * m[0], FloatModeFactor  * m[1])
            else
              @qtc.setRange(*m)
            end
          end
        end
      end

      define_simple_setter :value

      def orientation val
        case val
        when :horizontal then val = Qt::Horizontal
        when :vertical then val = Qt::Vertical
        end
        @qtc.orientation = val
      end

    public # methods of Slider

      def updateModel model, options = nil
#         tag "#{self}:updateModel #{model}, #{options}"
        cid = connector and
          if model && model.model_getter?(cid)
            if @floatmode
              @qtc.value = FloatModeFactor * model.model_apply_getter(cid)
#               tag "value := #{@qtc.value}"
            else
              @qtc.value = model.model_apply_getter(cid)
            end
          else
            @qtc.value = @qtc.minimum
          end
        super
      end

  end # Slider

  createInstantiator File.basename(__FILE__, '.rb'), Qt::Slider, Slider

end