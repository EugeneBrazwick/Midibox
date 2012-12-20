
require 'reform/app'

Reform::app {
  form {
    # IMPORTANT 'struct color: :red' will NOT work, since Qt::Color::colorNames
    # knows *nothing* about this symbol. (note to self: I expected it to work anyway)
    # Fortunately we can revert to strings without problem.
    struct color: 'red'
    vbox {
      combobox {
        # local data for the combobox:
        struct Qt::Color::colorNames
        # if changed, update 'color' in the forms data and propagate the change:
        connector :color
      }
      canvas {
        sizeHint 230
        area [0, 0, 100, 100]
        scale 2
        stroke :none
        circle {
          center 50, 50
          radius 30
          fill {
            color connector: :color
          }
        } # circle
      } # canvas
    } # vbox
  } # form
}

