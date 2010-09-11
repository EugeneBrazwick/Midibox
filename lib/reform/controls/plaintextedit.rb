
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative 'widget'

  # used for (possibly) bigger chunks of simple text.  For frame support and tables use TextEdit.
  class PlainTextEdit < Widget
  end # class PlainTextEdit

  createInstantiator File.basename(__FILE__, '.rb'), Qt::PlainTextEdit, PlainTextEdit

end # module Reform