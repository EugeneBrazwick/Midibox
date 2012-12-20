
require 'reform/app'

Reform::app {
  form {
    grid {
      columns 3
      parameters :canvas do
        sizeHint 220
        scale 2
        area [0, 0, 100, 100]
        background 'tan'
      end
      canvas {
        parameters :canvas
        for x in 0...100
          n = x.norm(0.0, 100.0)
          y = n ** 4 * 100
#           tag "point #{x}, #{y}"
          point at: [x, y]
        end
      } # canvas
      canvas {
        parameters :canvas
        for x in 0...100
          n = x.norm(0.0, 100.0)
          y = n ** 0.4 * 100
          point at: [x, y]
        end
      } # canvas
      canvas {
        parameters :canvas
        fill :none
        for x in (0...100).step(5)
          n = x.norm(0.0, 100.0)
          y = n ** 4 * 100
          circle center: [x, y], size: 120, pen: {weight: n * 5}
        end
      } # canvas
      canvas {
        parameters :canvas
        for x in (5...100).step(5)
          n = x.map(5, 95, -1, 1)
          p = n ** 4
          ypos = p.lerp(20, 80)
#           tag "x=#{x}, n=#{n}, p=#{p}, ypos=#{ypos}"
          line from: [x, 0], to: [x, ypos]
        end
      } # canvas
      canvas {
        parameters :canvas
        for x in 0...100
          n = x.norm(0.0, 100.0)
          line from: [x, 0], to: [x, 50], pen: { color: n, cap: :flat }
          line from: [x, 50], to: [x, 100], pen: { color: n ** 4, cap: :flat }
        end
      } # canvas
    } # grid
  } #form
} #app
