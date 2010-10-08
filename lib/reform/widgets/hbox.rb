
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative '../boxlayout'

  class HBox < BoxLayout
    def self.qtimplementor
      Qt::HBoxLayout
    end
  end # HBox

  createInstantiator File.basename(__FILE__, '.rb'), HBox.qtimplementor, HBox

end # Reform