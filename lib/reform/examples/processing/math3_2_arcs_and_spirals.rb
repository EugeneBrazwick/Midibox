
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
      canvas {
        parameters :canvas
        pen :none
        radius = 38
        for deg in (0...360).step(12)
          angle = 2 * Math::PI * deg / 360
          x = 50 + Math.cos(angle) * radius
          y = 50 + Math.sin(angle) * radius
          ellipse geometry: [x, y, 6, 6]
        end
      }
      canvas {
        parameters :canvas
        pen :none
        radius = 38
        for deg in (0...220).step(12)
          angle = 2 * Math::PI * deg / 360
          x = 50 + Math.cos(angle) * radius
          y = 50 + Math.sin(angle) * radius
          ellipse geometry: [x, y, 6, 6]
        end
      }
      canvas {
        parameters :canvas
        pen color: black, weight: 2.0, cap: :flat # even :round is very ugly here.
        # NOTE: 'processing' uses rads here. and turns clockwise.
        # Qt uses degrees and is counterclsockwise
#         circle center: [50, 55], radius: 45, fill: red, pen: { color: blue }
        arc center: [50, 55], radius: 25, to: 90 # NO ,  degrees.  Math::PI / 2
        arc center: [50, 55], radius: 30, from: 90, to: 180
        arc center: [50, 55], radius: 35, from: 180, to: 270
        arc center: [50, 55], radius: 40, from: 270, span: 90, fill: :none
      }
      canvas {
        parameters :canvas
        fill :none
        pen color: [0, 150], weight: 10, cap: :round
        for i in (0...160).step(10)
          arc center: [67, 37], radius: i/2, from: -i, span: -90
        end
      }
      canvas {
        parameters :canvas
        pen :none
        radius = 1.0
        for deg in (0 ... 360 * 6).step(11)
          angle = 2 * Math::PI * deg / 360
          ellipse center: [75 + Math.cos(angle) * radius, 42 + Math.sin(angle) * radius], radius: 3
          radius += 0.34
        end
      }
      canvas {
        parameters :canvas
        radius = 0.15
        cx, cy = 33, 66
        px, py = cx, cy
        for deg in (0 ... 360 * 5).step(12)
          angle = 2 * Math::PI * deg / 360
          x = cx + Math.cos(angle) * radius
          y = cy + Math.sin(angle) * radius
          line from: [px, py], to: [x, y]
          px, py = x, y
          radius *= 1.05
        end
      }
    }
  }
}
