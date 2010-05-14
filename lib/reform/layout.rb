
#Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative 'controls/frame'

=begin

added widgets must be recorded, but not added immediately.
Because when added their block has not yet been executed.
However it must be in postSetup.
=end
  class Layout < Frame
#     include FrameContext
  private

    define_simple_setter :margin, :sizeConstraint

    def fixedsize
      sizeConstraint Qt::Layout::SetFixedSize
    end

  public
    #override. A layout cannot be a parent for any widget
    def parent_qtc_to_use
      @containing_frame.qtc
    end

    def setLayoutposHack x, y, w, h
      raise ReformError, tr("This only works in a 'gridlayout'")
    end

    # override for layouts, returns added control
    def addControl control, &block
      q = if control.respond_to?(:qtc) then control.qtc else control end
      addWidget control, q
      @containing_frame.addControl control, &block
    end

    def stretch v = 1
      @qtc.addStretch v
    end

    def layout?
      true
    end

  end # Layout

end # Reform