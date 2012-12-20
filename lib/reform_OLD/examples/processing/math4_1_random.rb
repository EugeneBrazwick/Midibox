
require 'reform/app'

Reform::app {
  form {
    grid {
      columns 3
      parameters :canvas do
        sizeHint 220
        scale 2
        area [0, 0, 100, 100]
        background 'sandybrown'
      end
      2.times do
        canvas {
          parameters :canvas
          pen color: [0, 130], weight: 10
          5.times { line from: [0, rand(100)], to: [100, rand(100)] }
        }
      end
      2.times do
        canvas {
          parameters :canvas
          w = 20
          3.times do
            line from: [0, 5 + rand(40)], to: [100, 55 + rand(40)], pen: { color: [0.1 + 0.9 * rand, 0.9], weight: w }
          end
        }
      end
      2.times do
        canvas {
          parameters :canvas
          background black
          color = 255, 60
          for i in 0...100
            r = rand(10)
            line from: [i - 20, 100], to: [i + r * 5.0, 0], pen: { color: color, weight: r }
          end
        }
      end
    }
  }
}
