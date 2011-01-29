
# Copyright (c) 2011 Eugene Brazwick

require 'reform/app'

Duration = 4
LoopCount = -1

Reform::app {
  form {
    canvas {
      area 0, 0, 100, 100
      scale 2
      background 204
      circle {
        brush black
        center {
          x 50
          y animation: { from: -50, to: 150, loopCount: -1, duration: 5.seconds, startTime: 1.75.seconds }
        }
        radius 35
      } # circle
    } # canvas
  }
}