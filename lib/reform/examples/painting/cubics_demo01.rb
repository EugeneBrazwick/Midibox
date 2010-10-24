
# Copyright (c) 2010 Eugene Brazwick

=begin
  An important part of midibox will be the connection drawing using cubics.

  This should be as automatic as possible

  Let's develop some API.

  Painterpath is a good starting point and a way to
  display these is by constructing a Qt::GraphicsPathItem.
  It would be nice if you could build the path.
=end

require 'reform/app'

# introducing graphicspath

Reform::app {
  mainwindow {
    sizeHint 400, 320
    canvas {
      # graphicspath is calculated once and it will be possible to duplicate them
      # with a different matrix.
      # However, you cannot change a part of the path. Only set a completely new path.
#       tag "calling #{self}::pen"
      pen {
#         tag "self=#{self}"
        join :round
        size 7
      }
      graphicspath {
#         ellipse position: [100, 100], size: [200, 100]
        line 0,0, 100,0, 100,100, 0,100, :close
        # graphicspath ..... recursion should be possible
      }
    }
  }
}