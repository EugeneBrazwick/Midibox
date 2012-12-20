
# which shows us that the nesting order DOES matter

require 'reform/app'

W = H = 100

Reform::app {
  form {
    grid {
      columnCount 4
      parameters :canvas do
        sizeHint 2.2*W
        area [0, 0, W, H]
        scale 1.7
        background 'hotpink'
      end
      canvas {
        parameters :canvas
        circle radius: 2 # origin
        # hm.. the ion's are back:
        square geo: [-25, -25, 50], translation: [50, 50], fill: [blue, 0.3]
        square geo: [-25, -25, 50], rotation: 22.5, fill: [red, 0.3]
        square geo: [-25, -25, 50], translation: [50, 50], rotation: 22.5
      }
      canvas {
        parameters :canvas
        circle radius: 2  # origin
        square geo: [-25, -25, 50], rotation: 22.5, translation: [50, 50]
        # Both show that rotation is performed first, then translation!
      }
      # Q: so how to make the difference then??
      # A: use empties:
      canvas {
        parameters :canvas
        circle radius: 2 # origin
        empty {
          translation W / 2, H / 2
          empty {
            rotation 22.5
            square geo: [-25, -25, 50]
          } # empty
        } # empty
      } # canvas
      canvas {
        parameters :canvas
        rotation 22.5
        empty {
          translation W / 2, H / 2
          square geo: [-25, -25, 50]
        } # empty
        circle radius: 2 # origin
      } # canvas
      canvas {
        parameters :canvas
        empty {
          rotation 22.5
          empty {
            translation W / 2, H / 2
            square geo: [-25, -25, 50]
          } # empty
          circle radius: 2 # origin
        }
      } # canvas
      canvas {
        parameters :canvas
        translation 10, 60
        # this does not seem to work. Because Qt moves the area back into view anyway.
        rect geo: [0, 0, 70, 20]
        empty {
          rotation -15
          rect geo: [0, 0, 70, 20]
          rect geo: [0, 0, 70, 20], rotation: -30
        }
      } # canvas
      canvas {
        parameters :canvas
        translation 5, 20
        rotation 8
        # NOTE: all others have scale 2 !! These are smaller!!!
        scale 1.4
        rect geo: [0, 0, 70, 20]
        empty {
          rotation -15
          rect geo: [0, 0, 70, 20]
          rect geo: [0, 0, 70, 20], rotation: -30
        }
      } # canvas
      canvas {
        parameters :canvas
        circle radius: 2
        empty {
          translation 10, 60
          rect geo: [0, 0, 70, 20]
          empty {
            rotation -15
            rect geo: [0, 0, 70, 20]
            rect geo: [0, 0, 70, 20], rotation: -30
          }
        }
      } # canvas
    }
  }
}

