
# Copyright (c) 2010 Eugene Brazwick

=begin
  An important part of midibox will be the connection drawing using cubics.

  This should be as automatic as possible

  Let's develop some API.

  Painterpath is a good starting point and a way to
  display these is by constructing a Qt::GraphicsPathItem.
  It would be nice if you could build the path.

  -------------------------------
  Activepath.
  The fun starts now!

=end


require 'reform/app'

Reform::app {
  mainwindow {
    sizeHint 400, 320
    canvas {
      pen {
        join :round
        size 7
      }
      # the vertices on an activepath can be moved freely
      activepath {
        line 0,0, 100,0, 100,100, 0,100, :close
      }
    }
  }
}