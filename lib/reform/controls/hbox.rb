
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative '../boxlayout'

  class HBox < BoxLayout
  end # HBox

  createInstantiator File.basename(__FILE__, '.rb'), Qt::HBoxLayout, HBox

end # Reform