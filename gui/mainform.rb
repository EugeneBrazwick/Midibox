
require 'reform/app'

Reform::app {
  mainwindow {
    title tr('Midibox <nofile>')
    sizeHint 800, 600
    canvas {
      backgroundBrush '#ffe4a5'
    }
    menuBar {
      menu {
        title tr('&File')
        action {
          text tr('&New')
        }
        action {
          text tr('&Open...')
        }
        action {
          text tr('&Save...')
          shortcut 'Ctrl+S'
        }
        action {
          text tr('Save &as...')
        }
        separator
        quiter
      }
      menu {
        name :viewMenu
        title tr('&View')
      }
    }
    statusBar message: [tr('Ready for you!'), 10.seconds ]
    dock {
      name :nodePalette
      title 'Available Nodes'
      viewmenu :viewMenu
    }
  }
}