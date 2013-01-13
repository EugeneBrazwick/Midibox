
require_relative 'widget'

Reform.createInstantiator __FILE__, R::Qt::Slider

if __FILE__ == $0
  require 'reform/app'

  Reform::app {
    slider
  }
end
