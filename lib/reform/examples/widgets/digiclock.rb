
require 'reform/app'

Reform::app {
  # we need an explicit form ? no
  title tr('Digital Clock')
  # as a block:
#   lcdnumber {
#     name :current
#     makecenter
#     sizeHint 170, 70
#   }
  # as a oneliner:
  lcdnumber name: 'current', makecenter: true, sizeHint: [170, 70]
  time_model
}