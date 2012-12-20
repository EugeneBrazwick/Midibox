
require 'reform/app'

Reform::app {
  form {
    title tr('Color Editor Factory')
      # simpledata [ {..} .. ]   FAILS. Does not understand hash values. Was not meant for it either. FIXME
      # make sure each row as a ':key' value  or attribute (method 'key')
    structure value: [{ key: tr('Alice'), color: Qt::Color.new('aliceblue') },
                      { key: tr('Neptun'), color: Qt::Color.new('aquamarine') },
                      { key: tr('Ferdinand'), color: Qt::Color.new('springgreen') }]
    grid {
      tableview {
#         connector :self
#         verticalHeader { visible false }              This is by default
        sizeHint 150, 50
#         horizontalHeader {  # FIXME, it would be better if this could be applied to the last column,
            # as it seems a feature of the entire column.
# #           stretchLastSection true
#         }
        column {
          connector :key
          label tr('Name')
          resizeMode :fixed
        }
        column {
          connector :color
          label tr('Hair Color')
          resizeMode :stretched
          persistent_editor :colorlisteditor
#           editor {
#             connector :color
#           }           looks like duplicate code.
        }
      }
    }
  }
}