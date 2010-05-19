
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
      # but also the controls added to Layouts, since Qt layouts do not own them.
      @all_widgets = []
      # generate layouts automatically.
      # A layout can also be forced if a widget use a method only valid if its parent
      # is a layout, and the frame is not a layout.
      # in both cases @infused_layout is set.
      @autolayout = true
    end

    def check_formlayout control
#       tag "check_formlayout for #{control.class}"
      require_relative 'formlayout' # needed anyway
      unless layout = infused_layout
#         tag "instantiating formlayout!!!"
        ql = Qt::FormLayout.new
        layout = FormLayout.new(self, ql)
        @qtc.layout = ql
        @infused_layout = layout
      end
#       tag "addWidget #{control} to infused layout"
      control.containing_frame = layout
      layout.addWidget control, control.qtc
    end

    public

    attr_accessor :infused_layout
#     attr :autolayout

=begin rdoc
    connect a model (may be nil) to the frame.
    The rules are as follows:
        - if the frame has a connector and that name is also a public method of model,
          with no arguments (a getter therefore) and if model is not nil, then we
          apply the method and use the result to propagate to each control that
          is a direct child
        - if the frame has no name, or basically any other case then the first,
          it will take no action by itself,
          but the connect propagates to each control that is a direct child
=end
    def connectModel model, options = nil
#       tag "#{self}::connecting model, delegate to children, @all_widgets=#{@all_widgets.inspect}"
      if cid = connector && model && model.getter?(cid)
        model = model.send(cid)
      end
      for widget in @all_widgets
        widget.connectModel model, options
      end
      super
    end

    # does NOT add the control for Qt !!!, but it does so for layouts ??
    # it returns the added control
    def addControl control, &block
#       tag "#{self.class}::addControl(#{control}), layout?->#{control.layout?}, widget?->#{control.widget?}"
      raise 'assert failure, self cannot be a layout here' if layout?
      if control.widget?
        @all_widgets << control
          # similar to widget check_grid_parent
#         tag "control=#{control.inspect}"
        check_formlayout(control) if @autolayout && control.respond_to?(:labeltext)
      elsif control.layout?
        @all_widgets << control
        if layout = infused_layout
          control.containing_frame = layout
          layout.addWidget control, control.qtc
        else
#           tag "#{self.class}::addControl. SETTING layout of #@qtc to #{control.qtc}"
          raise "#{self} '#{name}' already has #{@qtc.layout} '#{@qtc.layout.objectName}'!" if @qtc.layout
          # Qt says the same but it's only a warning
          @qtc.layout = control.qtc
        end
  #       else
#         case control
#         when Timer then control.qtc.start
#         end
      end
      control.instance_eval(&block) if block
      control.postSetup
      control
    end

    # note that form has an override. Frames collect immediate controls.
    # Forms collect all controls, and they have an index too.
    def registerName aName, aControl
      aName = aName.to_sym
      define_singleton_method(aName) { aControl }
      containing_form.registerName(aName, aControl)
    end

    # override
    def postSetup
      super
      if instance_variable_defined?(:@infused_layout)
        @infused_layout.postSetup
        @infused_layout = nil
      end
    end
  end # class Frame

  QForm = QWidget # good enough

  createInstantiator File.basename(__FILE__, '.rb'), QForm, Frame

end # Reform