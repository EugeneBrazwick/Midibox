
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative 'checkbox'

  class RadioButton < CheckBox

  end

  createInstantiator File.basename(__FILE__, '.rb'), Qt::RadioButton, RadioButton

end # module Reform