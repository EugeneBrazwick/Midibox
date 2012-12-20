
require 'reform/app'

Reform::app {
  form {
    grid {
      columns 4
      parameters :canvas do
        sizeHint 110
#         scale 2
        area [0, 0, 100, 100]
        background 'springgreen'
      end
      canvas {
        parameters :canvas
        fill :none
        shape {
          # first and last are control points. Using the same algo as 'smooth'.
          # but with a twist on the endpoints.
          curve 20,80, 20,40, 30,30, 40,80, 80,80
          tension 0.7
        }
      } # canvas
      canvas {
        parameters :canvas
        fill :none
        shape {
          curve 20,0, 10,50, 30,90, 90,90, 95,40
        }
      } # canvas
      canvas {
        parameters :canvas
        fill :none
        shape {
          curve 10,90, 15,40, 20,20, 35,90, 90,90
        }
      } # canvas
      canvas {
        parameters :canvas
        fill :none
        shape {
          curve 40,95, 30,15, 85,15, 95,90, 95,90
        }
      } # canvas
      canvas {
        parameters :canvas
        fill :none
        shape {
          curve 0,40, 15,30, 30,40, 50,5, 70,40, 85,30, 100,40
          tension 0.8
        }
      } # canvas
      canvas {
        parameters :canvas
        fill :none
        shape {
          curve 0,70, 10,80, 45,60, 80,10, 60,8, 60,20, 90,40, 100,30
        }
      } # canvas
      canvas {
        parameters :canvas
        fill :none
        shape {
          # start + cp, cp + end:
          bezier 32,20, 80,5, 80,75, 30,75
          # this can be extended with (cp cp pt)*
        }
      } # canvas
      canvas {
        parameters :canvas
        fill :none
        shape {
          bezier 15,30, 20,-5, 70,5, 40,35,
                        5,70, 45,105, 70,70
        }
      } # canvas
      canvas {
        parameters :canvas
        pen :none
        shape {
          bezier 90,39, 90,39, 54,17, 26,83,
                        26,83, 90,107, 90,39
        }
      } # canvas
      canvas {
        parameters :canvas
        fill :none
        shape {
          bezier 15,40, 5,0, 80, 0, 50,55
          lineto 30,45, 25,75
          bezierto 50,70, 75,90, 80,70
        }
      } # canvas
      canvas {
        parameters :canvas
        fill :none
        shape {
          bezier 20,95, 10,65, 90,65, 80,10
        }
      } # canvas
      canvas {
        parameters :canvas
        fill :none
        shape {
          bezier 15,35, 95,95, 80,10, 20,80
        }
      } # canvas
      canvas {
        parameters :canvas
        fill :none
        shape {
          bezier 20,20, 5,5, -10,60, 35,65,
                        90,80, 80,95, 80,95
        }
      } # canvas
      canvas {
        parameters :canvas
        fill :none
        shape {
          bezier 80,5, 80,5, 20,20, 50,85,
                       50,85, 5,80, 5,30
        }
      } # canvas
    } # grid
  } # form
} # app