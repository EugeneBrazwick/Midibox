
require 'reform/app'

Reform::app {
  canvas {
#     pen size: 1.0
    sizeHint 420, 420
    area 0, 0, 100, 100
    scale 4
    def pt x; point pos: [x,x]; end
    def pts *xs; xs.each { |x| pt x }; end
    pts 20, 30, 40, 50, 60
#     line from: [20, 30], to: [30, 40]
#     line pos: [10, 10], from: [40, 30], to: [20, 60]
#     line pos: [45, 45], from: [40, 30], to: [40.1, 30.1]
#     line pos: [60, 60], from: [0, 0], to: [0.01, 0.01]
  }
}