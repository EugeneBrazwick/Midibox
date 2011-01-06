
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require 'reform/boxlayout'

  class VBox < BoxLayout
    def self.qtimplementor
      Qt::VBoxLayout
    end
  end

  createInstantiator File.basename(__FILE__, '.rb'), VBox.qtimplementor, VBox

end # Reform