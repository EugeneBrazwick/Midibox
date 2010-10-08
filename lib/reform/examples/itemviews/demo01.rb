
# Copyright (c) 2010 Eugene Brazwick

# This example uses plug-n-play techno to get the effect of the
# colorlisteditor.

require 'reform/app'

Reform::app {
  simplestruct key: 'white', color: Qt::Color.new(Qt::white)

  combo {
    simplestruct Qt::Color::colorNames.inject([]){|ary, el| ary << { key: el, color: Qt::Color.new(el) } }
    connector :key
    local_connector :key
    deco_connector :color
  }
  edit connector: :key
}

