
# Copyright (c) 2011 Eugene Brazwick

require 'reform/app'

Reform::app {
  form {
    grid {
      columns 2
      parameters :canvas do
        sizeHint 230
        area [0, 0, 100, 100]
        scale 2
        background 'paleturquoise'
      end
      which = {tl: true, tr: true, bl: true, br: true }
#       which = {br: true }
      which[:tl] and
      canvas {
        parameters :canvas
        duplicate {
          point at: [20, 20]
          translation 10, 10
          count 10
        }
      }
      which[:tr] and
      canvas {
        parameters :canvas
        duplicate {
          point at: [0, 0]
          translation 10, 8
          scale 0.95
          rotation 10
          count 10
        }
      }
      which[:bl] and
      canvas {
        parameters :canvas
        duplicate {
          pos 0, 9
          duplicate {
            point at: [0, 0]
            translation 0, 5
            count 5
          }
          rectangle geometry: [3, 0, 40, 5], fill: [blue, 0.5]
          translation 4, 14
          scale 0.90
          rotation -7
          count 40
        }
      }
      which[:br] and
      canvas {
        parameters :canvas
        duplicate {
          pos 50, 50
          circle center: [45, 0], radius: 5, fill: [red, 0.5]
          rotation 10
          count 36
        }
      }
    } # grid
  } # form
}