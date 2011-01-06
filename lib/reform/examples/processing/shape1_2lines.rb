
require 'reform/app'

Reform::app {
  form {
#     sizeHint 720
    grid {
      columnCount 2
      canvas {
        sizeHint 315
        area 0, 0, 100, 100
        scale 3
        line from: [10, 30], to: [90, 30]
        line from: [10, 40], to: [90, 40]
        line from: [10, 50], to: [90, 50]
      }
      canvas {
        sizeHint 315
        area 0, 0, 100, 100
        scale 3
        line from: [40, 10], to: [40, 90]
        line from: [50, 10], to: [50, 90]
        line from: [60, 10], to: [60, 90]
      }
      canvas {
        sizeHint 315
        area 0, 0, 100, 100
        scale 3
        line from: [25, 90], to: [80, 60]
        line from: [50, 12], to: [42, 90]
        line from: [45, 30], to: [18, 36]
      }
      canvas {
        sizeHint 315
        area 0, 0, 100, 100
        scale 3
        line from: [15, 20], to: [5, 80]
        line from: [90, 65], to: [5, 80]
      }
    }
  }
}