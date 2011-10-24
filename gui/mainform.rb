
require 'reform/app'
require 'midibox/config' # it's unavoidable anyway

# tag "CALLING internalize_dir"
Reform::internalize_dir File.absolute_path(File.dirname(__FILE__) + '/plugins')

Reform::app {
  dirname = Dir::home + '/.midibox'
  Dir::mkdir(dirname) unless Dir::exists?(dirname)
  rstore filename: dirname + 'database.db'
  rs = $qApp.model
  rs.config ||= Midibox::Config.new
  mainwindow {
#     tag "mainwindow parsed"
    title tr('Midibox <nofile>')
    sizeHint 800, 600
    soundcanvas
    menuBar {
      menu {
        title tr('&Project')
        filesystem $qApp.model.config
        fileNew
        fileOpen
        fileSave
        fileSaveAs
        separator
        action {
          label tr('E&xit')
          shortcut :quit
          statustip tr('Quit the application')
          whenTriggered { $qApp.quit if whenCanceled }
        }
      }
      menu {
#         name :editMenu
        title tr('&Edit')
        editUndo
        editRedo
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
      list {
        IconSize = 72
        iconsize IconSize
        gridSize 120
#         gridsize IconSize + 10  # Note that the grid must allow for the caption
  # to fit as well. So 'IconSize' is a bad choice.
        availablemidiboxnodes
        display :classname
        decorator :iconpath
        dragDropMode :dragonly
      }
    }
  }
}
