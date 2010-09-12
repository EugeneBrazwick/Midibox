
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative '../abstractbutton'

  class Button < AbstractButton
    include MenuContext # can create a menu here
    private
    define_simple_setter :flat

    public

  end

  createInstantiator File.basename(__FILE__, '.rb'), Qt::PushButton, Button

end # Reform