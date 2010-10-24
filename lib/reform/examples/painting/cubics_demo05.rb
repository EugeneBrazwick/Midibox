
# This demonstrates how to use animate single vertices.
# How to autocurve? Since controllpoints are a bit hard to animate
# an autosmoothing curve, together with animation, should make it possible
# to easily morph between two shapes.
# We need a :shapeRecipy. Define a shape but do not display it yet.
# Define two of them, assign 1 to the scene, and then add an animation
# from the first to the second and back again.
# This would make a pseudo 'circle' from the cube.

# First I need 'tension' or 'cuspness' that tweaks the autosmoothing.require 'reform/app'

require 'reform/app'

# this demo needs qtruby4631.patch to be applied!!!
# Use   sudo patch -p0 -E < qtruby4631.patch
# Diagnostics:
#               NoMethodError: undefined method `smoke' for nil:NilClass

Reform::app {
  mainwindow {
    sizeHint 640, 480
    canvas {
      area -50, -50, 200, 200
      scale 1.5
      pen {
        color :blue
        size 8
      }
      graphicspath {
        tension {
          sequence {  # naming is inconsistent. That's because we are in DynamicAttribute now...
                      # Only attributeanimation constructions are possible this way.
                      # However 'sequence' DOES call sequentialanimation anyway!
            looping # same as loopCount -1
            attributeanimation {
              from 0.0
              to 4.0
              duration 2.seconds
              easing :bounce
            }
            attributeanimation {
              from 4.0
              to 0.0
              easing :elastic
              duration 2.seconds
            }
            # AttributeAnimation in itself has code to store an array of values with timing points.
            # 'from' is used 0.0=>value
            # and 'to is 1.0=>value
            # Or an array of points with equal times in between:
            # values 0.0, 2.0, 0.0
            # It should be possible to supply a hash in one go.
            # And we can drop the 'sequence' around it.
            # demo06 can show this + rotations + colorhue rotation...
            # Also in demo06: we should allow AnimationContext in DynamicAttribute
          }
        }
        smooth 0,0, 100,0, 100,100, 0,100, :close
      }
    }
  }
}