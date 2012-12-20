
# Copyright (c) 2011 Eugene Brazwick

require 'reform/app'

# Please see the examples 001 to 003 first
Reform::app {
  title tr('Digital Clock')
  # as a block:
#   lcdnumber {
#     name :current
#     sizeHint 170, 70
#   }
  # as a oneliner:
  lcdnumber connector: :current, sizeHint: [170, 70]
  # So the properties become hashkeys, you must add a colon (important!)
  # and multiple values for a single property becomes an array.
  # Apart from that, the semantics are 100% identical.
  # The same code is running.
  time_model
}
