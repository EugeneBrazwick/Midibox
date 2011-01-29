
# two alternatives for the same animation

require 'reform/app'

Reform::app {
  form {
    hbox {
      canvas {
        area 0, 0, 100, 100
        scale 2
        brush color: black
        rect {
          topleft 0, 0
          width 100
          height {
            animation from: 0, to: 100, duration: 4.seconds   # the default is 250 (ms)
          }
        } # rect
      } # canvas
    }
  }
}
