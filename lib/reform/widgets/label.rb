
#  Copyright (c) 2013 Eugene Brazwick

require_relative 'frame'

module R::Qt
  class Label < Frame 
    public #methods of Label
      attr_dynamic String, :text, :html, :rawtext
  end

  # req. for a plugin:
  Reform.createInstantiator __FILE__, Label
end

if __FILE__ == $0
  require 'reform/app'
  Reform.app {
    widget {
      label {
	rawtext 'Hallo World!'
      }
    }
  }
end

