
# Copyright (c) 2013 Eugene Brazwick

require 'reform/app'

Reform::app {
  widget {
    size 980, 500
    collect_names true
    grid {
      columns 4
      define {
	canvas_setup parameters {
	 #	  minimumSize 210   # works fine but ....
	  area 100
	  scale 2
	  background 'paleturquoise'
	} # parameters
      } # define
      canvas {  # 1
        use :canvas_setup
        shape {
          moveto 30, 20
          lineto 85, 20
          lineto 85, 75
          lineto 30, 75
        } # shape
      } # canvas 1
      canvas { # 2
        use :canvas_setup
        shape {
          moveto 30, 20
	  # alternative way of producing a line:
          lineto [85, 20], [85, 75], [30, 75]
          # moveto + lineto -> line
          line 35,25, 90,25, 80,70, 25,70
          # line ALWAYS does a moveto and needs at least 4 values.
        } # shape
      } # canvas 2
      canvas { # 3
        use :canvas_setup
        shape {
          # however, for longer sequences that first 'moveto' is not that bad.
          lineto [30,20], [85,20], [85,75], [30,75]
          moveto 35, 25
          lineto 90,25, 80,70, 25,70, :close
          # line ALWAYS does a moveto and needs at least 4 values.
        } # shape
      } # canvas 3
      canvas { # 4
        use :canvas_setup
        shape {
	  fill :none
          line 30,20, 85,20, 85,75, 30,75, :close
        } # shape
      } # canvas 4
      canvas { # 5
        use :canvas_setup
        shape line: [30,20, 85,20, 30,75, 85,75]
      } # canvas 5
      canvas { # 6
        use :canvas_setup
        shape {
	  fill :black
          line 10,0, 100,30, 90,70, 100,70, 10,90, 50,40
        } # shape 6
      } # canvas
      canvas {  # 7
        use :canvas_setup
        shape {
	  pen weight: 20, cap: :round
          line 52,29, 74,35, 60,52, 61,75, 40,69, 19,75
        } # shape
      } # canvas 7
      canvas { # 8
        use :canvas_setup
        shape {
	  fill :black
	  pen :none
          moveto 40, 10
          for i in (20..100).step(5)
            lineto 20,i, 30,i
          end
          lineto 40, 100
        } # shape 8
      } # canvas
    } # grid
  } # widget
} # app
