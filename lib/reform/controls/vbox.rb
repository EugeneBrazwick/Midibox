
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative '../boxlayout'

  VBox = BoxLayout

  createInstantiator File.basename(__FILE__, '.rb'), Qt::VBoxLayout, VBox

end # Reform