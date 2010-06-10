
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

    define_simple_setter :margin, :sizeConstraint

    def fixedsize
      sizeConstraint Qt::Layout::SetFixedSize
    end

  public

    # override
    def addWidget2Parent parent_qtc, child_qtc
      parent_qtc.addLayout child_qtc
    end

    # override
    def effective_qtc
#       tag "#{self}::parent_qtc_to_use_for -> containing_frame*"
      frame = @containing_frame
      frame = frame.containing_frame until frame.widget?
      frame.qtc
    end

    def setLayoutposHack x, y, w, h
      raise ReformError, tr("This only works in a 'gridlayout'")
    end

    # override for layouts, returns added control
    # note that the Qt relationship for parents is already OK.
    def addControl control, quickyhash = nil, &block
#       tag "#{self}::addControl(#{control})"
# require_relative 'controls/checkbox' # FIXME
#       tag "stack:#{caller.join("\n")}" if self.is_a?(FormLayout) && control.is_a?(CheckBox)
      q = if control.respond_to?(:qtc) then control.qtc else control end
      @all_widgets << control
#       tag "calling addWidget(#{control.class})"
      addWidget control, q  # see addWidget
#       tag "#{control.class}.layout? -> #{control.layout?}"
#       if control.layout?
#         tag "setup the layout and done with it"
      control.instance_eval(&block) if block
      control.setupQuickyhash(quickyhash) if quickyhash
      control.postSetup
      control
#       else
         # WHY THEN????
#         frame = @containing_frame
#         frame = frame.containing_frame until frame.widget?
#         tag "#{self}::addControl add #{control.class} to containing_frame #{frame.class}"
#         frame.addControl(control, &block)   UNHEALTHY
#       end
#       tag "Added control"
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

    # Alternative: 'spacer space: v'
    def spacing v
      @qtc.addSpacing v
    end

    def layout?
      true
    end

    # override.
    def widget?
    end
  end # Layout

end # Reform