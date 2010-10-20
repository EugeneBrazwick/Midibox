
require 'reform/app'
require 'midibox/config' # it's unavoidable anyway

Reform::app {
  struct {
#       tag "executing block to struct, basicly executed in the Structure"
    self.configfile = filesystem {
#         tag "creating filesystem model"
      dirname Dir::home + '/.midibox'
      Dir::mkdir(dirname) unless Dir::exists?(dirname)
      klass Midibox::Config # used by yamlloader
      filename '/config.yaml.gz'
    }
    self.config = if configfile.exists?
      configfile.open_file
    else
      configfile.file = configfile.klass.new
    end
  } # struct
#   whenExiting do              TOO LATE == SEGV
#     tag "SAVE, self = #{self}"
#     model.configfile.save
#   end
  mainwindow {
#     tag "mainwindow parsed"
    title tr('Midibox <nofile>')
    whenCanceled do
#       tag "Save configfile"
      begin
        fileSaveAction.whenClicked
      ensure
        $qApp.model.configfile.save
      end
      true
    end
    sizeHint 800, 600
    canvas {
      backgroundBrush 241, 252, 126, 211
    }
    whenShown { fileNewAction.whenClicked }
    menuBar {
      menu {
        title tr('&File')
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