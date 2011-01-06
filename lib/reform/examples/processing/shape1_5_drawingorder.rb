
require 'reform/app'

Reform::app {
  form {
    sizeHint 560, 235
    grid {
      columnCount 2
      parameters :setup do
        sizeHint 230
        area [0, 0, 100, 100]
        scale 2
        background grey
      end
      canvas {
        parameters :setup
        rect geometry: [15, 15, 50, 50]
        circle center: [60, 60], size: 55
      }
      canvas {
        parameters :setup
        circle center: [60, 60], size: 55
        rect geometry: [15, 15, 50, 50]
      }
    }
  }
}