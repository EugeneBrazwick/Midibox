
require_relative 'widget'

module R::Qt
  class Label < Widget 
    public #methods of label
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

