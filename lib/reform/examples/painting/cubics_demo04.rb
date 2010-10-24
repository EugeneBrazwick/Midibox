
# Copyright (c) 2010 Eugene Brazwick

# Extending cubics_demo03 as demo2 related to demo1

require 'reform/app'

Reform::app {
  mainwindow {
    sizeHint 400, 320
    canvas {
      pen {
        color :blue
        cosmetic
      }
      activepath {
        smooth 0,0, 100,0, 100,100, 0,100, :close
      }
    }
  }
}