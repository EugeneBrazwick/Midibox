
module Reform
  require_relative 'control'

  class Widget < Control
  private
    # make it the central widget
    def central
      @owner.qcentralWidget = @owner.qtc.centralWidget = @qtc
    end

  public
    # override
    def widget?
      true
    end
  end # class Widget

  QWidget = Qt::Widget # may change
end # Reform