
module Reform
  require_relative 'control'

  class Widget < Control
  private
    # make it the central widget
    def central
      @form.qcentralWidget = @form.qtc.centralWidget = @qtc
    end

  public
    # override
    def widget?
      true
    end
  end # class Widget

end # Reform