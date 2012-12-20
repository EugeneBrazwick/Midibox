require 'reform/app'

Reform::app {
  form {
    grid {
      columns 4
      parameters :canvas do
        sizeHint 220
        scale 2
        area [0, 0, 100, 100]
      end
      canvas {
        parameters :canvas
        background 242, 204, 47
      } # canvas
      canvas {
        parameters :canvas
        background 174, 221, 60
      } # canvas
      canvas {
        parameters :canvas
        background 129, 130, 87
        stroke :none
        fill 174, 221, 60
        square geometry: [17, 17, 66]
      } # canvas
      canvas {
        parameters :canvas
        background 129, 130, 87
        fill :none
        pen color: [174, 221, 60], weight: 4, join: :miter
        square geometry: [19, 19, 62]
      } # canvas
      canvas {
        parameters :canvas
        background 116, 193, 206
        pen :none
        rect geometry: [20, 20, 30, 60], fill: [129, 130, 87, 102]
        rect geometry: [50, 20, 30, 60], fill: [129, 130, 87, 204]
      } # canvas
      canvas {
        parameters :canvas
        background 116, 193, 206
        pen :none
        x = 0
        for i in (51..255).step(51)
          rect geometry: [x, 20, 20, 60], fill: [129, 130, 87, i]
          x += 20
        end
      } # canvas
      canvas {
        parameters :canvas
        background 56, 90, 94
        w = 12
        line from: [30, 20], to: [50, 80], pen: { color: [242, 204, 47, 102], weight: w, cap: :round }
        line from: [50, 20], to: [70, 80], pen: { color: [242, 204, 47, 204], weight: w, cap: :round }
      } # canvas
      canvas {
        parameters :canvas
        background 56, 90, 94
        w = 12
        x = 0
        for i in (51..255).step(51)
          line from: [x, 20], to: [x + 20, 80], pen: { color: [242, 204, 47, i], weight: w, cap: :round }
          x += 20
        end
      } # canvas
    }# grid
  } # form
} #app
