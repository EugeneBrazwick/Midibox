
require 'reform/app'

Reform::app {
  mainwindow {
    sizeHint 600, 380
    canvas {
      rectangle {
        position 10, 10
        size 550, 70
        movable true
        simpletext text: <<-EOF, position: [-30, 16]
              The red circle is the parent, moving it moves everything linked to it, too.
              The blue square is a movable child, the green child cannot be moved on its
              own. You might also check the Z-order.
              EOF
      }
      circle {
        fill :red
        width 100
        position 50, 80
        movable true
        square fill: :blue, position: [50, 50], width: 160, movable: true
        square fill: :green, width: 60, rotation: 10
      }
    }
  }
}