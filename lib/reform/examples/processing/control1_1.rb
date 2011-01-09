
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
    struct x_left: 150, x_right: 50, x_bl: 150, x_br: 50
    grid {
      columnCount 2
      parameters :setup do
        sizeHint 230
        area [0, 0, Width, Height]
        scale 2
        background 'paleturquoise'
      end
      switch = 0xf
      if switch & 0x1 != 0x0
        # CERTIFIED OK
        vbox {
          slider {
            orientation :horizontal
            range 0..200
            connector :x_left
          }# slider
          canvas {
            parameters :setup
            circle {
              center 50, 50
              radius 18
              visible {
                connector { |data| data.x_left > 100 }
              }
            } # circle
            square {
              geometry 35, 35, 30
              visible {
                connector { |data| data.x_left < 100 }
              }
            } # square
            line from: [20, 20], to: [80, 80]
          } # canvas
        } # vbox
      end
      if switch & 0x2 != 0x0
        # EXACTLY THE SAME, except for the internal datastream
        vbox {
          slider {
            orientation :horizontal
            range 0..200
            connector :x_right
#             track_propagation true
          }# slider
          canvas {
            # this connector works like a filter, channeling the input 'struct' and
            # passing on the result 'x_left' to the components.
            connector :x_right
            parameters :setup
            circle {
              center 50, 50
              radius 18
              visible {
                connector { |x| x > 100 }
              }
            } # circle
            square {
              geometry 35, 35, 30
              visible connector: -> x { x < 100 }
            } # square
            line from: [20, 20], to: [80, 80]
          } # canvas
        } # vbox
      end
      if switch & 0x4 != 0x0
        vbox {
          slider {
            orientation :horizontal
            range 0..200
            connector :x_bl
          }# slider
          canvas {
            connector :x_bl
            parameters :setup
            circle {
              center 50, 50
              radius 18
              brush connector: -> x { [1.0, x > 100 ? (x - 100.0) / 100.0 : 0.0] }
              pen connector: -> x { [0.0, x > 100 ? (x - 100.0) / 100.0 : 0.0] }
            } # circle
            square {
              geometry 35, 35, 30
              brush connector: -> x { [1.0, x < 100 ? (100.0 - x) / 100.0 : 0.0] }
              pen connector: -> x { [0.0, x < 100 ? (100.0 - x) / 100.0 : 0.0] }
            } # square
            line from: [20, 20], to: [80, 80]
          } # canvas
        } # vbox
      end
     if switch & 0x8 != 0x0
        vbox {
          slider {
            orientation :horizontal
            range 0..200
            connector :x_br
          }# slider
          canvas {
            connector :x_br
            parameters :setup
            circle {
              center 50, 50
              radius 18
              brush connector: -> x { [1.0, x / 200.0 ] } # .tap{|t| tag "brushcol:=#{t.inspect}, x=#{x}"} }
              pen connector: -> x { [0.0, x / 200.0 ] }
            } # circle
            square {
              geometry 35, 35, 30
              brush connector: -> x { [1.0, (200.0 - x) / 200.0 ] }
              pen connector: -> x { [0.0, (200.0 - x) / 200.0] }
            } # square
            line from: [20, 20], to: [80, 80]
          } # canvas
        } # vbox
      end
    } # grid
  } # form
}
