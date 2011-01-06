
# Copyright (c) 2011 Eugene Brazwick

=begin

the example about conditionals has been extended to runtime changes.
The main reason is that the example does not make much sense.

x = 100
if x > 200 .... else .... end

to test this the code must be altered.

So I made 'x' changeable with a slider.

However, 'reform' does not draw stuff, it only declares it.
So how can we draw either A or B at runtime?

=end

require 'reform/app'

Width = Height = 100

Reform::app {
  form {
    sizeHint 280 * 2, 275 * 2
    struct x_left: 150, x_right: 50
    grid {
      columnCount 2
      parameters :setup do
        sizeHint 230
        area [0, 0, Width, Height]
        scale 2
        background 'paleturquoise'
      end
      vbox {
        slider {
          orientation :horizontal
          range 0..200
          connector :x_left
        }# slider
        canvas {
          connector :x_left
          parameters :setup
          circle {
            center 50, 50
            radius 18
            visible {
              connector { |x| x > 100 }
            }
          } # circle
=begin
          square {
            geometry 35, 35, 30
            visible {
              connector { |x| x < 100 }
            }
          } # square
          line from: [20, 20], to: [80, 80]
=end
        } # canvas
      } # vbox
=begin
      vbox {
        slider {
          orientation :horizontal
          range 0..200
          connector :x_right
        }# slider
        canvas {
          parameters :setup
        } # canvas
      } # vbox
=end
    } # grid
  } # form
}
