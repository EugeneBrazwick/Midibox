
# two alternatives for the same animation

require 'reform/app'

Reform::app {
  form {
    # whoops. Calling it 'count' serializes mixes up struct...
    struct counter: 50
    hbox {
=begin
      for some reason the lines here are drawn greyish though the pen is black.
      It might be that the replicators boundingbox is too small??
=end
      slider orientation: :vertical, range: 0..100, connector: :counter
      canvas {# I
#         viewportUpdateMode :all                # DOES NOT HELP
        area 0, 0, 100, 100
        scale 2
        pen color: black, weight: 1
        replicate {
          count connector: :counter
          line from: [0, 0], to: [100, 0]
          translation 0, 1
          # these lines do look greyish!!
        }
      } # canvas
      canvas {# I
        area 0, 0, 100, 100
        scale 2
        pen color: black, weight: 1
        for i in 0..100
          line from: [0, i], to: [100, i]
        end
      } # canvas
      canvas {# I
        area 0, 0, 100, 100
        scale 2
        pen color: black, weight: 1
        brush color: black
        rect {
          topleft 0, 0
          width 100
          height connector: :counter
        }
      } # canvas
    }
  }
}
