#!/usr/bin/ruby

# Copyright (c) 2010 Eugene Brazwick

require 'reform/app'

Reform::app {
=begin

It's not as easy as it seems.  Two classes are combined into a single unit.
However, I cannot easily declare an linenumberarea within a plaintextedit
since an edit is not supposed to have widgets.
So let's make it a frame and use two children instead. That's much more
natural.

Second, linenumberarea calls back methods of codeeditor

=end
#  FIXME: this example examples nothing...
# it should be possible to create a code editor using a plaintextedit only
# However, this example is also boring.

  autoform false
  codeeditor windowTitle: tr('Code Editor Example')
}