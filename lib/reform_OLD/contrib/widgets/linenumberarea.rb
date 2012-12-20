# Copyright (c) 2010 Eugene Brazwick


module Reform

  # this is used in the example examples/widgets/codeeditor.rb
  # this must be done different obviously. It must be possible to declare something within the
  # codeeditor.rb example
  # As a crude solution, the code can be copied right into codeeditor.rb
  class QLineNumberArea < Qt::Widget
    private
    def initialize editor
      super
      @codeEditor = editor
    end

    protected
    def paintEvent event
      @codeEditor.lineNumberAreaPaintEvent event
    end

    public
    def sizeHint
      Qt::Size.new(@codeEditor.lineNumberAreaWidth, 0)
    end

  end

  createInstantiator File.basename(__FILE__, '.rb'), QLineNumberArea
end
