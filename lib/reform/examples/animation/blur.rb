
# Copyright (c) 2011 Eugene Brazwick

require 'reform/app'

Reform::app {
  form {
    splash!
    canvas {
      image {
        source File.dirname(__FILE__) + '/images/kinetic.png'
        blur {
          radius {
            # problem: the blur from 50.0 to 25.0 changes halve (or less) from 25.0 to 0.0!
            # animation from: 50.0, to: 0.0, duration: 6.s
            # animation values: { 0.0=>50.0, 0.33=>30.0, 0.67=>12.0, 1.0=>0.0 }, duration: 6.s
            animation {
              from 50.0
              to 0.0
              easing :slowdown2
              duration 6.seconds
              whenFinished { close }
            }
          } # radius
        } # blur
      } # image
    } # canvas
  }
}