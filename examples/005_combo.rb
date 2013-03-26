
# Copyright (c) 2013 Eugene Brazwick

require 'reform/app'

include R
Reform::app {
  fail_on_errors true
  data 'behaviour' 
  frame {
    contentsMargins 4 # a property of widget
    shadow :sunken
    shape :styled_panel
    # storing a widget inside another creates a layout implicitely
    combo {
      # declare local data:
      data 'behaviour', 'development', 'cucumber', 'friends'
      # connector is applied to the global object
      connector :self 
      # 'display' is applied on the local object record indicated by the currently selected row
      # :self is actually the default
      display :self
    }
    # our edit shows the name, so we can see it change
    edit connector: :self
  }
}
