
require 'reform/app'

Reform::app {
  form {
    sizeHint 200, 100
    vbox {
      shadewidget {
#         shadetype :red
  #       sizePolicy :preferred, :fixed   BAD IDEA
      }
    }
  }
}