
# shapes...
# I skipped pointmode and linemode because it is... pointless

# All MODES for collecting shapes is stupid. If you want a triangle
# than use triangle.
# The only thing really unsupported are individual points.
# First, qt painterpaths do not support it.
# It is pointless
# You can fake it with a very short line, or a very small circle.

require 'reform/app'

Reform::app {
  form {
    grid {
      columnCount 3
      parameters :canvas do
        sizeHint 230
        area [0, 0, 100, 100]
        scale 2
        background 'hotpink'
      end
      canvas {
        parameters :canvas
        shape {
          # IMPORTANT: 'shape' can have any graphicitem as child, provided there is no
          # shape override, as for these:
          triangle 75,30, 10,20, 75,50
          triangle 20,60, 90,70, 35,85
          # so these 'triangles' cannot be given a pen or brush.
        }
      } # canvas
      canvas {
        parameters :canvas
        shape {
          triangle_strip 75,30, 10,20, 75,50, 20,60, 90,70, 35,85
        }
      } # canvas
      canvas {
        parameters :canvas
        shape {
          triangle_fan 10,20, 75,30, 75,50, 90,70
        }
      } # canvas
      canvas {
        parameters :canvas
        duplicate {
          count 2
          translation 0, 35
          shape {
            quad 30,25, 85,30, 85,50, 30,45
          }
        } # duplicate
      } # canvas
      canvas {
        parameters :canvas
        shape {
          # soldiers: left, right, left, right,....!!
          quad_strip 30,25, 85,30, 30,45, 85,50, 30,60, 85,65, 30,80, 85,85
        }
      } # canvas
      # same thing as a oneliner:
      canvas parameters: :canvas, shape: { quad_strip: [30,25, 85,30, 30,45, 85,50, 30,60, 85,65, 30,80, 85,85] }
      # ALL blocks can be turned into a hash. Except 'parameters' I think
    } # grid
  } # form
} # app
