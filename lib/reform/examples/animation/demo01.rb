
# Copyright (c) 2010 Eugene Brazwick, Parttime Genius

# A cube changes from red to blue

require 'reform/app'

Reform::app {
  canvas {
    sizeHint 230
#     area -200, -200, 200, 200
    circle {
      position -100, -100
      size 150
      brush {
        animation {
=begin

this is rather complicated. If we use a real 'brush' there is no way to interpolate.
If we use the symbol :red, it is even harder to grasp.
The only way this can work if the system understands that :red and :blue must be converted
to Qt::Color.

These are the supported Qt::Variant types supported by property animations:
  Int, Double + Float, QLine[F], QPoint[F], QSize[F], QRect[F] and QColor
=end
          from :red
          to :blue
          duration 10.seconds   # the default is 250.ms
        }
      }
    }
  }
}