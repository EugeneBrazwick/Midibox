
# Copyright (c) 2011 Eugene Brazwick

require 'reform/app'

Duration = 4
LoopCount = -1

=begin
Problematic stuff. It is not 100% in sync.
=end
Reform::app {
  form {
    hbox {
      canvas {
        area 0, 0, 100, 100
        scale 2
        background {
          color animation: { from: 0, to: 255, duration: Duration.seconds, loopCount: LoopCount }
        }
        line {
          from {
            x 0
            y animation: { from: 0, to: 100, duration: Duration.seconds, loopCount: LoopCount }
          }
          to {
            x 100
            y animation: { from: 0, to: 100, duration: Duration.seconds, loopCount: LoopCount }
          }
        } # line
      } # canvas
    }
  }
}