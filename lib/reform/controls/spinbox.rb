
module Reform

  require_relative '../labeledwidget'

  class SpinBox < LabeledWidget
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

    # specialValueText is the text for the 'minimum' value only.
    # Note that 'value' is an integer.
    define_simple_setter :value, :specialValueText, :prefix, :suffix, :wrapping

    public

    def updateModel model, options = nil
      cid = connector and
        if model && model.getter?(cid)
          @qtc.value = model.apply_getter(cid)
          @qtc.readOnly = !model.setter?(cid)
        else
          @qtc.value = @qtc.minimum
        end
      super
    end

  end

  createInstantiator File.basename(__FILE__, '.rb'), Qt::SpinBox, SpinBox

end