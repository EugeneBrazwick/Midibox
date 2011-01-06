
require 'reform/app'

=begin
IMPORTANT: there is no such thing as 'setting a fill until another one is set'.

This is a crucial difference with 'processing' which is iterative.

'reform' is declarative. A shape without an explicit brush will refer to the
brush in the parent. If you say:

    canvas {
      brush red
      rect ....  # no brush/fill set
      brush blue
    }

then the rectangle will be blue.

IT MUST BE BLUE!!!!

=end
Reform::app {
  form {
    sizeHint 280, 235
    grid {
      columnCount 4
      canvas {
        sizeHint 230
        area [0, 0, 100, 100]
        scale 2
        background gray
#         tag "***FILL := RED***"
        fill red
        square topleft: [25, 25], size: 50
#         tag "***FILL := BLUE***"
        fill blue
      }
    }
  }
}