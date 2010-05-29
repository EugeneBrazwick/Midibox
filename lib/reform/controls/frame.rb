
module Reform

  require_relative 'widget'

=begin rdoc

a Frame is a widget that may contain others.
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
    def connectModel aModel, options = nil
#       tag "#{self}::connecting model, delegate to children, @all_widgets=#{@all_widgets.inspect}"
      if cid = connector && aModel && aModel.getter?(cid)
        aModel = aModel.send(cid)
      end
      for widget in @all_widgets
        unless widget.effectiveModel?
#           tag "WIDGET #{widget} '#{widget.name}' REFUSES model!!!!!!!!!!!!!"
#         else
#           tag "propagate to #{widget} '#{widget.name}'"
          widget.connectModel aModel, options
        end
      end
      super
    end

    # override
    def setModel aModel, quickyhash = nil, &initblock
      @model ||= nil
      unless @model.equal?(aModel)
        @model.removeObserver_i(self) if @model
        @model = aModel
        @model.addObserver_i(self) if @model
      end
      super
    end

    # override
    def effectiveModel
      return @model if instance_variable_defined?(:@model)
      @containing_frame.effectiveModel
    end

    # override
    def effectiveModel?
      instance_variable_defined?(:@model)
    end

    # does NOT add the control for Qt !!!, but it does so for layouts ??
    # it returns the added control
    def addControl control, quickyhash = nil, &block
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
      control.setupQuickyhash(quickyhash) if quickyhash
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

  createInstantiator File.basename(__FILE__, '.rb'), QWidget, Frame

end # Reform