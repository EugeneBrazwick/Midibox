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
          geo 0, 0, 50, 100
          visible -> mouse { mouse.sceneX < 50 }
        }
        rect {
          geo 50, 0, 50, 100
          visible -> mouse { mouse.sceneX >= 50 }
        }
      }
      canvas {
        parameters :canvas_params
        mouse
        rect {
          geo 40, 20, 40, 60
          fill {
            color -> mouse { (40..80).include?(mouse.sceneX) && (20..80).include?(mouse.sceneY) ? white : black }
          }
        }# rect
      } # canvas
    }# grid
  }
}