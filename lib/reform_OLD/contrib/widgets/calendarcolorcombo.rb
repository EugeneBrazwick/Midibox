
# Copyright (c) 2010-2011 Eugene Brazwick

module Reform

  require 'reform/widgets/combobox'

  # this would be better if it supported all basic colors.
  # Now it is a completely unusable thingamabob
#   class QCalendarColorCombo < Qt::ComboBox
#     private
#     def initialize qparent
#       super
#       addItem tr('Red'), Qt::Variant.new(Qt::red)
#       addItem tr('Blue'), Qt::Variant.new(Qt::blue)
#       addItem tr('Black'), Qt::Variant.new(Qt::black)
#       addItem tr('Magenta'), Qt::Variant.new(Qt::magenta)
#     end
#   end

  QCalendarColorCombo = Qt::ComboBox

  class CalendarComboBox < ComboBox
    def initialize parent, qtc
      super
      struct Qt::red => tr('Red'),
             Qt::blue => tr('Blue'),
             Qt::black => tr('Black'),
             Qt::magenta => tr('Magenta')
      key_connector :self
    end
  end

  createInstantiator File.basename(__FILE__, '.rb'), QCalendarColorCombo, CalendarComboBox

end
