
module Reform

  require_relative 'widget'

  class Slider < Widget
    private

    def initialize parent, qtc
      super
      # I expect that changing the signal 1 tick, actually has effect immediately
      # Otherwise another kind of control would be used.
      connect(@qtc, SIGNAL('valueChanged(int)'), self) do |value|
        rfRescue do
          model = effectiveModel and cid = connector and model.apply_setter(cid, value)
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

    public

    def updateModel model, options = nil
      cid = connector and
        if model && model.getter?(cid)
          @qtc.value = model.apply_getter(cid)
        else
          @qtc.value = @qtc.minimum
        end
      super
    end

  end

  createInstantiator File.basename(__FILE__, '.rb'), Qt::Slider, Slider

end