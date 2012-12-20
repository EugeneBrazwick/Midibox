
=begin
  note to the unaware:
    you cannot push and pop matrixes.
    This violates the principle of declarational design.

    But nothing stops you of wrapping items within an 'empty'.

=end

require 'reform/app'

Reform::app {
  form {
    grid {
      columnCount 3
      parameters :canvas do
        sizeHint 230
        area [0, 0, 100, 100]
        scale 2
        background 'hotpink'
      end
      canvas {
        parameters :canvas
        rect geo: [0, 5, 70, 30]
        empty {
          rect geo: [0, 5, 70, 30]
          # yes we made the rectangle before setting the position of the empty,
          # but that does not matter
          pos 10, 30
        } # empty
      } # canvas
      canvas {
        parameters :canvas
        rect geo: [0, 5, 70, 30]
        empty {
          translate 10, -10
          rect geo: [0, 5, 70, 30]
        } # empty
      } # canvas
      canvas {
        parameters :canvas
        rect geo: [0, 5, 70, 30]
        empty {
          translate 10, 30
          rect geo: [0, 5, 70, 30]
          empty {
            translate 10, 30
            rect geo: [0, 5, 70, 30]
          } # empty
        } # empty
      } # canvas
      canvas {
        parameters :canvas
        empty {
          translate 33, 0
          rect geo: [0, 20, 66, 30]
          rect geo: [0, 50, 66, 30]
        } # empty
      } # canvas
      canvas {
        parameters :canvas
        empty {
          translate 33, 0
          rect geo: [0, 20, 66, 30]
        }
        rect geo: [0, 50, 66, 30]
      } # canvas
      canvas {
        parameters :canvas
        empty {
          translate 20, 0
          rect geo: [0, 10, 70, 20]
          empty {
            translate 30, 0
            rect geo: [0, 30, 70, 20]
          }
          rect geo: [0, 50, 70, 20]
        }
        rect geo: [0, 70, 70, 20]
      } # canvas
    }
  }
}
