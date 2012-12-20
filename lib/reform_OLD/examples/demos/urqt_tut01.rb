
# Copyright (c) 2010

# Who's afraid of Ruby? Use ruby for qt!

# A New Adagium: You Are Qute! Use Ruby for Qt!

# U_R_Qt

=begin
No not really
 import Qt 4.7

 Rectangle {
     id: page
     width: 500; height: 200
     color: "lightgray"

     Text {
         id: helloText
         text: "Hello world!"
         y: 30
         anchors.horizontalCenter: page.horizontalCenter
         font.pointSize: 24; font.bold: true
     }
 }
=end

require 'reform/app'

Reform::app {
  mainwindow {
    sizeHint 500, 200
    canvas {
    # QML must play dirty! anchorlayout can only layout gwidgets...
    # not simple graphicitems. So we need another proxylayer?
    # THIS  IS STUPID!
    # Only Qt::GraphicsWidget can be managed, and the only implementation is
    # Qt::GraphicsProxyWidget which can contain, a GraphicsView and then
    # we can store our Rectangle or Text in that.....
    # Is this changed in Qt4.7 ???
      graphicswidget {
        anchorlayout { # this will induce a Qt::GraphicsWidget in between
                      # since a layout can only be set in a QGWidget.
          rectangle {
            color :lightgray
            anchor name: :pageCenter, at: :horizontalCenter
          }
          simpletext {
            value 'Hello world!'
            y 30
            horizontalCenter :pageCenter
            font {
              pointSize 24
              bold
            }
          }
        }
      }
    }
  }
}
