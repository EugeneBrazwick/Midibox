
# Copyright (c) 2010 Eugene Brazwick

=begin
A model which is an array with hashes

If the records (in the array) support the method 'id'
=end

require 'reform/app'

MyData = [{ section: 'Scientific Research', count: 21, color: '#99e600'},
          { section: 'Engineering & Design', count: 18, color: '#99cc00'},
          { section: 'Automotive', count: 14, color: '#99b300'},
          { section: 'Aerospace', count: 13, color: '#9f991a'},
          { section: 'Automation & Machine Tools', count: 13, color: '#a48033'},
          { section: 'Medical & Bioinformatics', count: 13, color: '#a9664d'},
          { section: 'Imaging & Special Effects', count: 12, color: '#ae4d66'},
          { section: 'Defense', count: 11, color: '#b33380'},
          { section: 'Test & Measurement Systems', count: 9, color: '#a64086'},
          { section: 'Oil & Gas', count: 9, color: '#994d8d'},
          { section: 'Entertainment & Broadcasting', count: 7, color: '#8d5a93'},
          { section: 'Financial', count: 6, color: '#806699'},
          { section: 'Consumer Electronics', count: 4, color: '#8073a6'},
          { section: 'Other', count: 38, color: '#8080b3'}
      ]

Reform::app {
  # setting up a datasource in the application, for the second list
  struct current: 'Medical & Bioinformatics', current2: 6, data: MyData
  hbox {
# =begin
    list {
      # the first list has its own data:
      struct MyData
      local_connector :section #{ |rec| rec.section }
      connector :current
      key_connector :section # this is important
      decorator :color
      sizeHint 340, 460
    }
# =end
# =begin
    vbox {
      # This list should take the model using the model connector.
      # Therefore the result should be the same.
      # The only problem is that the current row should also be retrieved like this.
      list {
        model_connector [:root, :data]
        local_connector :section #{ |rec| rec.section }
        connector :current
        key_connector :section # this is important
        decorator :color
        sizeHint 340, 460
      }
      edit connector: :current
    }
# =end
# =begin
    vbox {
      # This list should take the model using the model connector.
      # Therefore the result should be the same.
      # The only problem is that the current row should also be retrieved like this.
      list {
        model_connector [:root, :data]
        local_connector :section #{ |rec| rec.section }
        key_connector :numeric_index # special value
        connector :current2
        decorator :color
        sizeHint 340, 460
      }
      edit connector: [:current2]
    }
# =end
  }
}
