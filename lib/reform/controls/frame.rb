
module Reform

  require_relative '../widget'

=begin rdoc

a Panel is a widget that may contain others.
=end
  class Frame < Widget
    include FrameContext

    private

    def initialize frame, qtc
      super
      # all immediate controls within this panel are in here
      # but also the controls added to Layouts, since Qt layouts does not own them.
      @all_widgets = []
    end

    public

    # does NOT add the control for Qt !!!, but it does so for layouts ??
    # it returns the added control
    def addControl control, &block
      if control.widget?
        @all_widgets << control
      elsif control.layout?
        @qtc.layout = control.qtc
      end
      control.instance_eval(&block) if block
      control.postSetup
    end

  end # class Frame

  # forward definition
  class Layout < Frame
  end

  createInstantiator File.basename(__FILE__, '.rb'), QWidget, Frame # QWidget catches resize + close events

end # Reform