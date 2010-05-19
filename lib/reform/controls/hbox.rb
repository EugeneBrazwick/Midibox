
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative '../layout'

  class HBox < Layout
  end # HBox

  createInstantiator File.basename(__FILE__, '.rb'), Qt::HBoxLayout, HBox

end # Reform