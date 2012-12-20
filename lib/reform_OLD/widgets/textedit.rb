
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative 'widget'

  class TextEdit < Widget

    def_delegators :@qtc, :toPlainText, :document, :clear, :textCursor

  end # class TextEdit

  createInstantiator File.basename(__FILE__, '.rb'), Qt::TextEdit, TextEdit

end # module Reform