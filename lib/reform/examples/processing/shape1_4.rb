
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
        p1, p2, c1, c2 = [32, 29], [30, 75], [80, 5], [80,75]
        bezier from: p1, to: p2, controlpoints: [c1, c2]
        line from: p1, to: c1
        ellipse center: c1, radius: 2
        line from: c2, to: p2
        ellipse center: c2, radius: 2
      }
      canvas {
        parameters :setup
        p1, p2, c1, c2 = [85, 20], [15, 80], [40, 10], [60, 90]
        bezier from: p1, to: p2, controlpoints: [c1, c2]
        line from: p1, to: c1
        ellipse center: c1, radius: 2
        line from: c2, to: p2
        ellipse center: c2, radius: 2
      }
    }
  }
}