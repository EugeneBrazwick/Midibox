require 'reform/app'

Reform::app {
  form {
    grid {
      columns 2
      define {
        canvas_params parameters {
          area 0, 0, 100, 100
          scale 2
          background 'hotpink'
          mouseTracking true
          pen :none
        }
      }# define
      canvas {
        parameters :canvas_params
        mouse
        rect {
          geo 25, 25, 50, 50
          fill {
            color -> mouse { if mouse.pressed? then white else black end }
          }
        } # rect
      } # canvas
      canvas {
        parameters :canvas_params
        mouse
        rect {
          geo 25, 25, 50, 50
          fill {
            # IMPORTANT 'mouse.button' refers to the button causing an event.
            color -> mouse { b = mouse.buttons
                             case
                             when b[:left] then black
                             when b[:right] then white
                             else gray
                             end }
          }
        } # rect
      } # canvas
    }# grid
  }
}