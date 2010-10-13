
# Copyright (C) 2010 Eugene Brazwick

=begin

this example shows how data is propagated through something called 'connector'.
This 'connector' is applied to the Structure (or other Model) to get
and set the values in the edits.

If you change the text in one edit, the structure itself (through the special connector :self)
is altered and the change is propagated to all controls in the system.
=end

require 'reform/app'

Reform::app {
  struct 'Hallo World'
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