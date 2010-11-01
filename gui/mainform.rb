
require 'reform/app'
require 'midibox/config' # it's unavoidable anyway

# tag "CALLING internalize_dir"
Reform::internalize_dir File.absolute_path(File.dirname(__FILE__) + '/plugins')

Reform::app {
  struct {
#     tag "executing block to struct, basicly executed in the Structure, self = #{self}"
    self.configfile = filesystem {
#         tag "creating filesystem model"
      dirname Dir::home + '/.midibox'
      Dir::mkdir(dirname) unless Dir::exists?(dirname)
      klass Midibox::Config # used by yamlloader
      filename '/config.yaml.gz'
    }
#     tag "self.configfile is now #{self.configfile.inspect}"
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
        cfg = $qApp.model.configfile
        fileSaveAction.whenClicked if cfg.dirty?
        raise 'progerror' unless cfg.clean?
      ensure
        cfg.save if cfg.dirty?
      end
      true
    end
    sizeHint 800, 600
    soundcanvas
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
