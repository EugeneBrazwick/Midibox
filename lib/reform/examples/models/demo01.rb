
# Copyright (C) 2010 Eugene Brazwick

require 'reform/app'

Reform::app {
  ruby_model value: 'Hallo World'
  edit(connector: :self)
  edit connector: :self
  edit connector: :self
  edit connector: :self
#   button { text 'something' }
#   trace do
#     button { text 'something' }
#   end
#     tag "calling #{self}#edit"
  edit connector: :self
#   end
#     button { text 'something' }
#     edit { connector :self }
}