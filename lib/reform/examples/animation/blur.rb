
# Copyright (c) 2011 Eugene Brazwick

require 'reform/app'

Reform::app {
  form {
    canvas {
      image {
        source File.dirname(__FILE__) + '/images/kinetic.png'
        blur {
          radius {
            # problem: the blur from 50.0 to 25.0 changes halve (or less) from 25.0 to 0.0!
            animation from: 50.0, to: 0.0, duration: 6.s
          } # radius
        } # blur
      } # image
    } # canvas
  }
}