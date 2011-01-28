
# Showing that empties can be skipped too

require 'reform/app'

W = H = 100

Reform::app {
  form {
    grid {
      columnCount 2
      parameters :canvas do
        sizeHint 2.1 * W
        area [ 0, 0, W, H ]
        scale 1.9
        background 'hotpink'
      end
      canvas {
        parameters :canvas
        translation W / 2, H / 2
        line from: [-W / 2, 0], to: [W / 2, 0]
        line from: [0, -H / 2], to: [0, H / 2]
        empty {
          pen :none
          fill 255, 204
          circle center: [0, 0], size: 45
          circle center: [-W / 2, H / 2], size: 45
          circle center: [W / 2, -H / 2], size: 45
        }
      }
      canvas {
        sizeHint 2.1 * W
        # if I change the area to [-1,-1,1,1] and no translation
        # I expected the same. But it does not work correctly??
        area [ 0, 0, 2, 2 ]
        scale W, H
        translation 1.0, 1.0
        background 'hotpink'
        line from: [-1.0, 0.0], to: [1.0, 0.0]
        line from: [0.0, -1.0], to: [0, 1.0]
        empty {
          pen :none
          fill 255, 204
          circle center: [0, 0], size: 0.9
          circle center: [-1, 1], size: 0.9
          circle center: [1, -1], size: 0.9
        }
      }
      canvas {
        # Like this:
        sizeHint 2.1 * W
        area [ -1, -1, 1, 1 ]
        scale W, H
        background 'hotpink'
        line from: [-1.0, 0.0], to: [1.0, 0.0]
        line from: [0.0, -1.0], to: [0, 1.0]
        empty {
          pen :none
          fill 255, 204
          circle center: [0, 0], size: 0.9
          circle center: [-1, 1], size: 0.9
          circle center: [1, -1], size: 0.9
        }
      }# canvas
      canvas {
        # Like this:
        sizeHint 2.1 * W
        area [ 0, 0, W, H ]
        scale 2.0, -2.0
        # strangely enough, no translation is required at all??
        background 'hotpink'
        line from: [0.0, 1.0], to: [W, 1.0]
        line from: [0.0, 1.0], to: [0, H]
        empty {
          pen :none
          fill 255, 204
          circle center: [0, 0], size: 45
          circle center: [W/2, H/2], size: 45
          circle center: [W, H], size: 45
        }
      }# canvas
    }
  }
}