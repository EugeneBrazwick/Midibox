
require 'reform/app'

=begin
IMPORTANT: there is no such thing as 'setting a fill until another one is set'.

This is a crucial difference with 'processing' which is iterative.

'reform' is declarative. A shape without an explicit brush will refer to the
brush in the parent. If you say:

    canvas {
      brush black
      rect ....  # no brush/fill set
      brush white
    }

then the rectangle will be white.

=end
Reform::app {
  form {
    sizeHint 280, 235
    canvas {
      sizeHint 230
      area [0, 0, 100, 100]
      scale 2
      background black
      square topleft: [10, 10], size: 50
      square topleft: [20, 20], size: 50, stroke: lightGray
      square topleft: [30, 30], size: 50, stroke: gray
      square topleft: [40, 40], size: 50, stroke: darkGray
    }
  }
}