
require 'reform/app'

Reform::app {
  mainwindow {
    structure value: { color: :blue, enable_colors: false }, name: :data
#     title { # we MUST open a block to set this connector.
#       connector { |m| (tr('A %s Circle') % m.color).capitalize }
#     }
    # Not true, alternative syntax   title, connector: -> m { ... }
    title connector: -> struct { (tr('A %s Circle') % struct.color).capitalize }
    size 400, 250
    canvas {
      scene {
#         area -110.0, -110.0, 220.0, 220.0 # topleft + size(!) NOT rightbottom !!
        circle {
          position 50, 50
          radius 40
#           fill :blue
          fill connector: :color
        }
      }
    }
    menuBar {
      menu {
        text tr('&Pick a color')
        action {
          text tr('&Blue')
          value :blue
          connector :color
          enabler connector: :enable_colors
        }
        action {
          text tr('&Green')
          value :green
          connector :color
          enabler connector: :enable_colors
        }
        action {
          text tr('&Red')
=begin
           this is ambiguous.  Since the constructor emits 'toggled'
          checkable # to verify double signals, optional since 'checked' also sets it.
          checked true  # set this BEFORE connecting stuff, or it will make the circle red!

the problem with BOTH a value and checked is that unchecking it will make color: nil.
=end
          checked false # set this BEFORE connecting stuff, or it will make the circle brushless
          value :red
          connector :color
          enabler connector: :enable_colors
        }
        action {
          text tr('Enable color changes')
          value true
          connector :enable_colors
        }
        quiter
      }
    }
  }
}