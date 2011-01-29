
=begin

  Copyright  (c) 2011 Eugene Brazwick

Now we dive into data and animations.

First, let's break up a color into r,g,b and a.

  WOW!!!!

  NOBEL prize !!

=end

require 'reform/app'

Reform::app {
  form {
    struct red: 211, blue: 45, green: 35, alpha: 255
    hbox {
      for i in [:red, :blue, :green, :alpha]
        vbox {
          label text: i.to_s.capitalize
          slider orientation: :vertical, range: 0..255, connector: i
        }
      end
      canvas {
        background gray
        scale 2.0
        area 0, 0, 100, 100
        sizeHint 220
        circle {
          center 50, 50
          radius 25
          # do not forget 'brush'.
          # using 'color' immediately just calls Graphical::color, which is 'make_color'.
          # we should avoid ambiguous stuff like color == brush when defining components.
          brush {
            # Now we could say 'color  red'.  But that would be boring!
            # Let's assign a ruby block instead:
            color {
              # Once more, we could say 'red 211' here or 'red 0.8'.
              # However, currently, if using a connector the result must be an integer.
              # I don't think implementing floats is problematic as long as all four
              # components use the same kind of data.
              red connector: :red
              blue connector: :blue
              green connector: :green
              alpha connector: :alpha
              # You can obviously also connect red to :blue and blue to :red
            } # color
          } # brush
        } # circle
      } # canvas
    } # hbox
  } # form
} # app
