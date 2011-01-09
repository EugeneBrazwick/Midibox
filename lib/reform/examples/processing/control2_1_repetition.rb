
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
        for i in (20...80).step(5)
          line from: [20, i], to: [80, i + 15]
        end
      } # canvas
      canvas {
        parameters :setup
        for x in (-16...100).step(10)
          line from: [x, 0], to: [x + 15, 50]
        end
        for x in (-8...100).step(10)
          line from: [x, 50], to: [x + 15, 100], pen: { weight: 4 }
        end
      } # canvas
      canvas {
        parameters :setup
        fill :none
        for d in (10..150).step(10)
          circle center: [50, 50], size: d
        end
      } # canvas
      canvas {
        parameters :setup
        for i in (0...100).step(2)
          line from: [i, 0], to: [i, 100], stroke: 255 - i
        end
      } # canvas
    } #grid
  } # form
} # app
