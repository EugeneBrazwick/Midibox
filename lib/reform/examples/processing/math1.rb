
# Copyright (c) 2011 Eugene Brazwick

# Since this is pure ruby, math is really no big deal.

# NOTE: this programming style is EVIL, since it uses 'change of state'.
# Also note that 'processing' uses a paint method that actually draws things
# 'reform' cannot paint, you can only declare 'shapes'.
# If the state changes between frames this is noticeable (popvote says noticable) in 'processing', but
# since 'reform' does a one-time construction it remains static forever.

require 'reform/app'

Height = Width = 100

Reform::app {
  form {
    sizeHint 280 * 4, 235 * 2
    grid {
      columnCount 4
      parameters :setup do
        sizeHint 230
        area [0, 0, Width, Height]
        scale 2
        background 'paleturquoise'
      end
      canvas {
        parameters :setup
        grayVal, sz = 153, 55
        square topleft: [10, 10], size: sz, fill: grayVal
        grayVal += 102
        square topleft: [35, 30], size: sz, fill: grayVal
      } # canvas
      canvas {
        parameters :setup
        a = 30
        # 'processing' uses 'height'. And Widget#height exists too.
        # however, this code is run during construction time and the height is not yet set
        # to its final position (it seems to be around 30).
        # We could use sizeHint.height though.
        # However, that's in pixels, and does not use the logical coordinate system.
        # sizeHint.height / scale is closer, but scale could be a Qt::SizeF as well.
        # also it would be 230/2 = 115 iso 100.
        line from: [a, 0], to: [a, Height]
        a += 40
#         tag "line to #{a}, #{sizeHint.height}"
#         line from: [a, 0], to: [a, sizeHint.height / scale]
        line from: [a, 0], to: [a, Height]
      } # canvas
      canvas {
        parameters :setup
        a, b = 30, 40
        line from: [a, 0], to: [a, Height]
        line from: [b, 0], to: [b, Height]
        line from: [b - a, 0], to: [b - a, Height], stroke: { weight: 4, cap: :flat }
      } # canvas
      canvas {
        parameters :setup
        a, b = 8, 10
        line from: [a, 0], to: [a, Height]
        line from: [b, 0], to: [b, Height]
        line from: [a * b, 0], to: [a * b, Height], stroke: { weight: 4, cap: :flat }
      } # canvas
      canvas {
        parameters :setup
        a, b = 8.0, 10.0
        line from: [a, 0], to: [a, Height]
        line from: [b, 0], to: [b, Height]
        line from: [a / b, 0], to: [a / b, Height], stroke: { weight: 4, cap: :flat }
      } # canvas
      canvas {
        parameters :setup
        for y in (20..38).step(6)
          line from: [0, y], to: [Width, y]
        end
      } # canvas
      canvas {
        parameters :setup
        y = 20
        4.times do
          line from: [0, y], to: [Width, y]
          y *= 1.6
        end
      } # canvas
    } # grid
  } # form
}
