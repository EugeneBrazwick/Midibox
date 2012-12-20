
require 'reform/app'

=begin
IMPORTANT: there is no such thing as 'setting a fill until another one is set'.

This is a crucial difference with 'processing' which is iterative.

'reform' is declarative. A shape without an explicit brush will refer to the
brush in the parent. If you say:

    canvas {
      brush black
      rect ....  # no brush/fill set
      brush white
    }

then the rectangle will be white.

=end
Reform::app {
  form {
    sizeHint 280 * 4, 235 * 2
    grid {
      columnCount 4
      parameters :setup do
        sizeHint 230
        area [0, 0, 100, 100]
        scale 2
        background gray
      end
      canvas {
        parameters :setup
        square topleft: [10, 10], size: 50
        rect geometry: [20, 20, 50], fill: 204
        square geometry: [30, 30, 50], fill: 153
        square topleft: [40, 40], size: 50, fill: 102
      }
      canvas {
        parameters :setup
        background black
        square topleft: [10, 10], size: 50
        square topleft: [20, 20], size: 50, stroke: lightGray
        square topleft: [30, 30], size: 50, stroke: gray
        square topleft: [40, 40], size: 50, stroke: darkGray
      }
      canvas {
        parameters :setup
        # IMPORTANT: there is no such thing as 'setting a fill until another one is set'.
        # IMPORTANT: that was a lie. Let's say you should not use this fact.
        # so the next example is how it should work
        # empty draws nothing but can contain graphics. It also has a pen + brush + transformationmatrix.
        # 'empty' as in Blender.
        empty {
          fill red
          # setting the fill above influences the contained items
          square topleft: [8, 8], size: 50
          square topleft: [16, 16], size: 50
          square topleft: [24, 24], size: 50
        }
        fill blue # hm.... ambiguous value. Does it apply to earlier created rectangles? YES!
                  # if they are immediate children without an explicit fill.
        # obviously local fills override the one in the parent
        square topleft: [32, 32], size: 50, fill: black
        # also, empty passes on the parents attributes if left alone:
        empty square: { topleft: [40, 40], size: 50 }# , fill: black
      }
      canvas {
        parameters :setup
        # same example the 'EVIL' way:
        fill red
        square topleft: [8, 8], size: 50
        square topleft: [16, 16], size: 50
        square topleft: [24, 24], size: 50
        fill blue
        square topleft: [32, 32], size: 50, fill: black
        square topleft: [40, 40], size: 50
      }
      canvas {
        parameters :setup
        background 0
        # whiteness + opaqueness. Integers in range 0..255 (or 0.0 to 1.0)
        color = 255, 220
        square topleft: [15, 15], size: 50, fill: color
        square topleft: [35, 35], size: 50, fill: color
      }
      canvas {
        parameters :setup
        rect geometry: [0, 40, 100, 20], fill: black
        # NOTE: 'fill white, 51' is terribly(?) wrong since 'white' is a full brush/fill by itself
        # and not a constant like '255'!
        # note to self: color + alpha as a constructor is not that bad.
        rect geometry: [0, 20, 33, 60], fill: [255, 51]
        rect geometry: [33, 20, 33, 60], fill: [255, 127]
        rect geometry: [66, 20, 34, 60], fill: [255, 204]
      }
      canvas {
        parameters :setup
        square geometry: [10, 10, 50]
        # 'disable' the fill/brush:
        square geometry: [20, 20, 50], fill: :none
        square geometry: [30, 30, 50], fill: :none
      }
      canvas {
        parameters :setup
        rectangle geometry: [10, 15, 20, 70]
        # similar for the pen/stroke
        rectangle geometry: [40, 15, 20, 70], stroke: :none
        rectangle geometry: [70, 15, 20, 70], pen: :none
      }
    }
  }
}