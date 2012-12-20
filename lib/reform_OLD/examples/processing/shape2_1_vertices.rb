
require 'reform/app'

Reform::app {
  form {
    grid {
      columnCount 4
      parameters :canvas do
        sizeHint 230
        area [0, 0, 100, 100]
        scale 2
        background 'paleturquoise'
      end
      canvas {
        parameters :canvas
        fill :none
#         pen weight: 3
        shape {
#           smooth 0,0, 100,0, 100,100, 0,100, :close
=begin .  This does a move 4 times. Single vertices in a shape are invisible as
          we should create an outline.
          vertex 30, 20
          vertex 85, 20
          vertex 85, 75
          vertex 30, 75

The initial condition is such that the first lineto becomes a moveto.
The preferred way is then to use moveto:
=end
          moveto 30, 20
          lineto 85, 20
          lineto 85, 75
          lineto 30, 75
        } # shape
      } # canvas
      canvas {
        parameters :canvas
        fill :none
        shape {
          moveto 30, 20
          lineto 85,20, 85,75, 30,75
          # moveto + lineto -> line
          line 35,25, 90,25, 80,70, 25,70
          # line ALWAYS does a moveto and needs at least 4 values.
        } # shape
      } # canvas
      canvas {
        parameters :canvas
        fill :none
        shape {
          # however, for longer sequences that first 'moveto' is not that bad.
          lineto 30,20, 85,20, 85,75, 30,75
          moveto 35, 25
          lineto 90,25, 80,70, 25,70, :close
          # line ALWAYS does a moveto and needs at least 4 values.
        } # shape
      } # canvas
      canvas {
        parameters :canvas
        fill :none
        shape {
          line 30,20, 85,20, 85,75, 30,75, :close
        } # shape
      } # canvas
      canvas {
        parameters :canvas
        fill :none
        shape {
          line 30,20, 85,20, 30,75, 85,75
        } # shape
      } # canvas
      canvas {
        parameters :canvas
        fill black
        shape {
          line 10,0, 100,30, 90,70, 100,70, 10,90, 50,40
        } # shape
      } # canvas
      canvas {
        parameters :canvas
        fill :none
        pen weight: 20, cap: :round
        shape {
          line 52,29, 74,35, 60,52, 61,75, 40,69, 19,75
        } # shape
      } # canvas
      canvas {
        parameters :canvas
        fill black
        pen :none
        shape {
          moveto 40, 10
          for i in (20..100).step(5)
            lineto 20,i, 30,i
          end
          lineto 40, 100
        } # shape
      } # canvas
    } # grid
  } # form
} # app
