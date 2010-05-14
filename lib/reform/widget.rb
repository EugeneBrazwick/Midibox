
module Reform
  require_relative 'control'

  class Widget < Control
  private
    # make it the central widget
    def central
      @owner.qcentralWidget = @owner.qtc.centralWidget = @qtc
    end

    def colspan w
      span 1, w
    end

    def rowspan h
      span h, 1
    end

    def font f = nil
      return @qtc.font unless f
      @qtc.font = f
    end

  public
    # override
    def widget?
      true
    end

    # this only works if the widget is inside a gridlayout
    def span rows = nil, cols = nil
      return (instance_variable_defined?(:@span) ? @span : nil) unless rows
      cols ||= rows
#       tag "span := #{rows},#{cols}"
      @span = rows, cols
    end

    # this only works if the widget is inside a gridlayout
    def layoutpos row = nil, col = nil
      return (instance_variable_defined?(:@layoutpos) ? @layoutpos : nil) unless row
      @layoutpos = row, col
    end

    define_simple_setter :windowTitle

  end # class Widget

  QWidget = Qt::Widget # may change
end # Reform