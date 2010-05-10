#!/usr/bin/ruby

require_relative '../../app'

Reform::app {
  canvas {
    scene {
       area -100.0, -100.0, 100.0, 100.0 # topleft - rightbottom
       circle {
           position -50, -50
           radius 25
           fill red
         }
       circle {
           position 50, 50
           radius 25
           fill yellow
         }
       circle {
           position -50, 50
           radius 25
           fill blue
         }
       circle {
           position 50, -50
           radius 25
           fill green
         }
          # this is nice, but you do not want it to draw 60 second markings...
    } # scene
    #antialiasing true   this is the default
    title tr('Analog Clock')
    size 400, 400
  }
}