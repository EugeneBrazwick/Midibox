
#  Copyright (c) 2013 Eugene Brazwick

require_relative '_layout'

  # req. for a plugin:
Reform.createInstantiator __FILE__, R::Qt::VBoxLayout

if __FILE__ == $0
  require 'reform/app'
  Reform.app {
    widget {
      vbox {
	edit text: 'Hallo'
	edit text: 'World!'
      }
    }
  }
end

