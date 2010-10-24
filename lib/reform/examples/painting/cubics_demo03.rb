
# Copyright (c) 2010 Eugene Brazwick

# Extending cubics_demo02
# This demonstrates an autosmooth curve

#Autosmoothing: code inspired from inkscape source: void Node::_updateAutoHandles()
# GPL-ed.

require 'reform/app'

Reform::app {
  mainwindow {
    sizeHint 400, 320
    canvas {
      pen {
        join :round
        size 3
      }
      graphicspath {
        smooth 0,0, 100,0, 100,100, 0,100, :close
      }
    }
  }
}