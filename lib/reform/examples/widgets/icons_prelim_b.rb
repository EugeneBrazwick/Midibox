# Table test

require 'reform/app'

Reform::app {
  mainwindow {
    table {
      dir = Dir.getwd + File.dirname(__FILE__) + '/images/'
      require_relative '../../models/icon_example_model'
      model [IconExampleEntry.new(dir + 'designer.png'),
             IconExampleEntry.new(dir + 'qtopia_48x48.png')]
#       colCount 3
      horizontalHeader defaultSectionSize: 90 # this is not a constructor, but a reference
      column label: tr('Image'), connector: :name, stretchMode: true #, editable: false FOLLOWS FROM model
      column {
        label tr('Mode')
        fixedMode true
        connector :mode
        model_connector :available_modes
        editor :combobox
      }
      column {
        label tr('State')
        fixedMode true
        connector :state
        model_connector :available_states
        #editor :combobox         default when model_connector is applied
      }
      rowCount 4
    }
  }
}