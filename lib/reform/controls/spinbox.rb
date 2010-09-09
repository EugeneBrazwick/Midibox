
module Reform

  require_relative '../labeledwidget'

  class SpinBox < LabeledWidget
    private

    def range m, n = nil
      n ? @qtc.setRange(m, n) : @qtc.setRange(*m)
    end

    define_simple_setter :value, :specialValueText
  end

  createInstantiator File.basename(__FILE__, '.rb'), Qt::SpinBox, SpinBox

end