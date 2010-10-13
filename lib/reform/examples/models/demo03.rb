
# Copyright (c) 2010 Eugene Brazwick

require 'reform/app'

Reform::app {
  # we need an explicit form, to setup our datasource
  form {
    # the data associated with this form is simply 'red'  (a ruby string, not 'simply red' obviously)
    sizeHint 480, 260
    struct 'red'
    hbox {
      list {
        # note that setNamedColor can complain about nonexisting colors. How to test if it is present?
        # the X11 list used to be different, see wikipedia where 'cornflower' is present.
        # But in my /usr/share/X11/rgb.txt all traces of it are gone.
        # NO NO NO. Qt uses another list and even disables X11 colors.
        # Hmm. It could be that both lists are now the same?
        struct %w[blue crimson AliceBlue green red chocolate yellow thisisnotacolor]
        # setting up a 'connector' will cause the list to change its selection to the
        # matching row, and also to broadcast the rowdata when the selection changes
        # 'self' indicates we match with the datasource as a whole.
        connector :self
      }
      canvas {
        circle {
          # same principle here. It will be red, but clicking the list will change it.
          brush connector: :self
        }
      }
    }
  }
}