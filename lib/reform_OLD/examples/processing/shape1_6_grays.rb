
require 'reform/app'

Reform::app {
  form {
    sizeHint 280 * 3, 235
    grid {
      columnCount 3
      parameters :setup do
        sizeHint 230
        area [0, 0, 100, 100]
        scale 2
      end
      canvas {
        parameters :setup
        background 0
      }
      canvas {
        parameters :setup
        background 124
      }
      canvas {
        parameters :setup
        background 230
      }
    }
  }
}