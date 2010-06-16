# Table test

require 'reform/app'

Reform::app {
  mainwindow {
    tag "self=#{self}, calling model??"
    require_relative '../../models/icon_example_model'
    dir = Dir.getwd + File.dirname(__FILE__) + '/images/'
    ruby_model value: [IconExampleEntry.new(dir + 'designer.png'),
                       IconExampleEntry.new(dir + 'qtopia_48x48.png')]
    table {
#       colCount 3
      noSelection
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