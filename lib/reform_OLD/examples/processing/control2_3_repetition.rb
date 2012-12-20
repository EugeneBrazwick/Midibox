
# Copyright (c) 2011 Eugene Brazwick

# Same as control2_2, but no iterators at all.

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
        duplicate {
          pos 10, 10
          duplicate {
            point  # at: [ 0, 0]
            translation 0, 10
            # IMPORTANT: translate also exists, but is the same as 'pos' !!
            count 10
          }
          translation 10, 0
          count 10
        } # duplicate
      } # canvas
      canvas {
        parameters :setup
        fill 0, 36
        stroke :none
        duplicate {
          pos -10, -10
          duplicate {
            ellipse radius: [15, 10]
            scale 1.1, 1.0
            count 10
            translation 2, 10
          }
          count 10
          translation 10, 2
        }
      } # canvas
      canvas {
        parameters :setup
        stroke :none
        iter = (0...100).step(10)
        # obviously the squares are easy enough,
        # but the colors?? This is a brush effect similar to
        for y in iter
          for x in iter
            square geometry: [x, y, 10], fill: (x + y) / 180.0
          end
        end
      } # canvas
      canvas {
        parameters :setup
=begin
  to do stuff like this with a duplicator we need a way to set count based on a scaler
  in the other one.

  To be more precise, we need a GENERIC way of applying step-operations to ANY parameter.
  Translation,Scale and Rotation are just specific cases where we operate on QDuplicate.matrix.

  Google Summer of Code please oh please.....
=end
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
