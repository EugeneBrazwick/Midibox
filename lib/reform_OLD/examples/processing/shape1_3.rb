
require 'reform/app'

Reform::app {
  form {
    sizeHint 1020, 470
    grid {
      columnCount 4
      SizeHint = 230
      Area = [0, 0, 100, 100]
      Scale = 2
      Background = Reform::Graphical::grey
      parameters :setup do
        sizeHint SizeHint
        area Area
        scale Scale
        background Background
      end
      canvas {
        parameters :setup
#         pen black     DEFAULT
#         tag "setting black brush, class = #{self.class}"
#         fill(black) WRONG  WHITE is OK
        triangle points: [60, 10, 25, 60, 75, 65]
        line from: [60, 30], to: [25, 80]
        line from: [25, 80], to: [75, 85]
        line from: [75, 85], to: [60, 30]
      }
      canvas {
        parameters :setup
        triangle points: [55, 9, 110, 100, 85, 100]
        triangle points: [55, 9, 85, 100, 75, 100]
        triangle points: [-1, 46, 16, 34, -7, 100]
        triangle points: [16, 34, -7, 100, 40, 400]
      }
      canvas {
        parameters :setup
        quad points: [38, 31, 86, 20, 69, 63, 30, 76]
      }
      canvas {
        parameters :setup
        quad points: [20, 20, 20, 70, 60, 90, 60, 40]
        quad points: [20, 20, 70, -20, 110, 0, 60, 40]
      }
      canvas {
        parameters :setup
        rect geometry: [15, 15, 40]
        rect geometry: [55, 55, 25]
      }
      canvas {
        parameters :setup
        rect geometry: [0, 0, 90, 50]
        rect geometry: [5, 50, 75, 4]
        rect geometry: [24, 54, 6, 6]
        rect geometry: [64, 54, 6, 6]
        rect geometry: [20, 60, 75, 10]
        rect geometry: [10, 70, 80, 2]
      }
      canvas {
        parameters :setup
          # 'pos' actually translate the coordinate system
        qtcircle pos: [10, 10], size: 60
        qtcircle topleft: [59, 59], radius: 16
      }
      canvas {
        parameters :setup
        rfellipse center: [35, 0], size: 120
        rfellipse center: [38, 62], size: 6
        circle center: [40, 100], radius: 35
      }
    }
  }
}
