
module Reform

  require_relative 'widget'

  class SpinBox < Widget
    private

    def range m, n = nil
      n ? @qtc.setRange(m, n) : @qtc.setRange(*m)
    end

    define_simple_setter :value
  end

  createInstantiator File.basename(__FILE__, '.rb'), Qt::SpinBox, SpinBox

end