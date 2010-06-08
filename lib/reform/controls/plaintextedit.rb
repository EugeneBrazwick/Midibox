
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative '../controls/widget'

  class PlainTextEdit < Widget
  end # class PlainTextEdit

  createInstantiator File.basename(__FILE__, '.rb'), Qt::PlainTextEdit, PlainTextEdit

end # module Reform