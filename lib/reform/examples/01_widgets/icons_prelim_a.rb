
# a Bar Menu

require 'reform/app'

Reform::app {
#   mainwindow {
    menuBar {
      menu {
        title 'File'
        action text: 'File'
        action text: 'Exit'
      }
      separator
      menu {
        title 'Help'
        action text: 'Help'
      }
    }
#   }
}