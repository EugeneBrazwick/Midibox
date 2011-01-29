
module Reform

  require_relative 'widget'

  class Slider < Widget
    private

      def initialize parent, qtc
        super
        # I expect that changing the slider by even a little should have effect immediately
        # Otherwise another kind of control should be used.
        connect(@qtc, SIGNAL('valueChanged(int)'), self) do |value|
          rfRescue do
#             tag "#{self}::valueChanged in #{value}, track_propagation = #{track_propagation}"
            if (mod = model) && (cid = connector)
#               tag "APPLY_SETTER"
              model.apply_setter(cid, value, self)
            end
          end
        end
      end

      # note this resembles SpinBox a lot
      def range m, n = nil
        if n
          @qtc.setRange(m, n)
        else
          if Range === m
            @qtc.setRange(m.min, m.max)
          else
            @qtc.setRange(*m)
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
          if model && model.getter?(cid)
            @qtc.value = model.apply_getter(cid)
          else
            @qtc.value = @qtc.minimum
          end
        super
      end

  end # Slider

  createInstantiator File.basename(__FILE__, '.rb'), Qt::Slider, Slider

end