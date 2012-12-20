
# Copyright (c) 2010 Eugene Brazwick

# Once more an AWESOME demo!

# A few lists with extra roles

require 'reform/app'

Reform::app {
  form {
    hbox {
#       columncount 2
      # This list demonstrates changing the font of specific entries
      list {
        fontdb
        local_connector :family
        itemfont :self
      }
      # This list demonstrates changing the color of specific entries
      # Maybe we need a cache around it, as the color-lookup seems sluggish
      # And of course how do we set the itembackground appropriately
      list {
        struct Qt::Color::colorNames
        itemcolor :self
        itembackground { |color| if Reform::Graphical::make_color(color).lightnessF > 0.85 then :darkGray else :white end }
      }
      list {
        struct Reform::Graphical::colorkeys
        itemdecoration :self
      }
    }
  }
}