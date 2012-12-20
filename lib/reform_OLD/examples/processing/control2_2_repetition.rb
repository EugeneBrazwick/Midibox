
# Literal copy of original 'processing' example.

require 'reform/app'

Reform::app {
  form {
    grid {
      columnCount 2
      parameters :setup do
        sizeHint 230
        area [0, 0, 100, 100]
        scale 2
        background 'paleturquoise'
      end
      canvas {
        parameters :setup
        iter = (10...100).step(10)
        for y in iter
          for x in iter
            point at: [x, y]
          end
        end
      } # canvas
      canvas {
        parameters :setup
        fill 0, 36
        stroke :none
        iter = (-10..100).step(10)
        for y in iter
          for x in iter
            ellipse center: [x + y / 8.0, y + x / 8.0], radius: [15 + x / 2.0, 10.0]
          end
        end
      } # canvas
      canvas {
        parameters :setup
        stroke :none
        iter = (0...100).step(10)
        for y in iter
          for x in iter
            square geometry: [x, y, 10], fill: (x + y) / 180.0
          end
        end
      } # canvas
      canvas {
        parameters :setup
        for y in (1...100).step(10)
          for x in (1...y).step(10)
            line from: [x, y], to: [x + 6, y + 6]
            line from: [x + 6, y], to: [x, y + 6]
          end
        end
      } # canvas
    } #grid
  } # form
} # app
