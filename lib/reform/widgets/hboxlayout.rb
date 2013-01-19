
#  Copyright (c) 2013 Eugene Brazwick

require_relative '../layout'

# req. for a plugin:
Reform.createInstantiator __FILE__, R::Qt::HBoxLayout

if __FILE__ == $0
  require 'reform/app'
  Reform.app {
    widget {
      hbox {
	edit text: 'Hallo'
	edit text: 'World!'
      }
    }
  }
end

