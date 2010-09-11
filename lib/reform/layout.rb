
#Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative 'controls/frame'

=begin

added widgets must be recorded, but not added immediately.
Because when added their block has not yet been executed.
However it must be in postSetup.
=end
  class Layout < Frame
  private

    def initialize parent, qtc
#       tag "new Layout #{self}"
      super(parent, qtc, false)
    end

    define_simple_setter :margin, :sizeConstraint, :spacing

    def fixedsize
      sizeConstraint Qt::Layout::SetFixedSize
    end

  public

    # override
    def effective_qtc
#       tag "#{self}::parent_qtc_to_use_for -> parent*"
      frame = parent
      frame = frame.parent until frame.widget?
      frame.qtc
    end

    def setLayoutposHack x, y, w, h
      raise ReformError, tr("This only works in a 'gridlayout'")
    end

    def add control, hash, &block
      control.setup(hash, &block)
      added control
    end

    def addTo parent, hash, &block
      parent.addLayout self, hash, &block
    end
=begin
    defaults are ambigous since x.stretch is supposed to return stretch, not set it to 1.
    also, defaults are unclear by design.
    There is another ambiguity here. If a layout is within another layout, does
    stretch 'add' a stretch or does it apply on the stretch added to the layout itself,
    when added to its parent.

    Since we actually add a kind of widget, let's make this explicit.
    So 'stretch' becomes a control property and effects the current control, as it
    is added to the parent layout.

    And 'spacer stretch: 1' will be the syntax here.
=end
#     def stretch v
#       @qtc.addStretch v
#     end

    # Alternative: 'spacer spacing: v'
    # There is a cockup here.  There is also 'setSpacing'!!!! Do not confuse.  FIXME ???
#     def spacing v
#       @qtc.addSpacing v
#     end

    def layout?
      true
    end

    # override.
    def widget?
    end

    # override. If self is the class of the child, which qtc to use as parent
    def self.parent_qtc parent_control, parent_effective_qtc
    end

  end # Layout

end # Reform