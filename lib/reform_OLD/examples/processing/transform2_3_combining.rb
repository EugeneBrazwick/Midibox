
# Showing that empties can be skipped too

require 'reform/app'

W = H = 100

Reform::app {
  form {
    grid {
      columnCount 3
      parameters :canvas do
        sizeHint 2.1 * W
        area [0, 0, W, H]
        scale 1.7
        background 'hotpink'
      end
      canvas {
        parameters :canvas
        circle radius: 2 # origin
        rect {
          translation 45, 60
          geo -35, -5, 70, 10
          rect {
            rotation -30
            geo -35, -5, 70, 10
            rect {
              geo -35, -5, 70, 10
              # local order does not matter
              rotation -30
            }
          }
        }
      }
      canvas {
        parameters :canvas
        fill :none
        pen weight: 1
        rect {
          geo 0, 0, 20, 10
          translation 10, 20
          rect {
            geo 0, 0, 20, 10
            scale 2.2
            rect {
              geo 0, 0, 20, 10
              scale 2.2
            }
          }
        }
      }
      canvas {
        parameters :canvas
        fill :none
        pen weight: 1
        rect {
          translation 50, 30
          geo -10, 5, 20, 10
          rect {
            geo -10, 5, 20, 10
            scale 2.5
          }
        }
      } # canvas
      canvas {
        parameters :canvas
        background black
        empty {
          translation 66, 33
          for i in 0...18
            line {
              from 0, 0
              to 55, 0
              rotation (i + 1) * 15
              pen color: [255, 120], weight: i, cap: :round
            }
          end
        }
      } # canvas
      canvas {
        background black
        stroke :none
        fill 255, 48
        empty {
          translation 33, 66
          for i in 0...12
            circle center: [4, 2], radius: 10, scale: 1.2 ** (i + 1)
          end
        }
      } # canvas
      canvas {
        background black
        stroke :none
        empty {
          translation 33, 66
          for i in 0...24
            circle center: [3, 2], radius: 8, scale: 1.1 ** (i + 1), brush: { color: hsv(120 + i * 6, 255, 255, 35) }
          end
        }
      } # canvas
    }
  }
}

