
module Reform

  require_relative 'widget'

=begin rdoc

a Frame is a widget that may contain others.
=end
  class Frame < Widget
    include ControlContext

    private

    def initialize frame, qtc, autolayout = true
#       tag "CREATING FRAME, qtc=#{qtc}"
      super(frame, qtc)
      # all immediate controls within this panel are in here
      # but also the controls added to Layouts, since Qt layouts do not own them.
      @all_children = []
      # generate layouts automatically.
      # A layout can also be forced if a widget use a method only valid if its parent
      # is a layout, and the frame is not a layout.
      # in both cases @infused_layout is set.
      @autolayout = autolayout
    end

    # note hash and block are setups for 'control'
    def check_layout control, creator = :formlayout, hash = nil, &block
      unless layout = infused_layout
        # problematic: the creator tends to call postSetup, but it must be delayed
#         tag "missing layout, create a '#{creator}'"
        layout = send(creator, postSetup: false)
#         tag "#{self}, qtc=#@qtc, layout=#{layout}, layout.qtc=#{layout.qtc}, creator='#{creator}'"
        @qtc.layout = layout.qtc
        @infused_layout = layout
      end
      if control
#         tag "addWidget #{control} to infused layout + SETUP"
        control.containing_frame = layout
        layout.add control, hash, &block
      end
      layout
    end

    def added control
      @all_children << control
      control.containing_frame = self
    end

    public

    attr_accessor :infused_layout

    # array of all controls, widgets, layouts, menus, actions, models etc..
    attr :all_children
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
    def updateModel aModel, options = nil
#       tag "#{self}::connecting model, delegate to children, @all_widgets=#{@all_widgets.inspect}"
      aModel = aModel.send(cid) if cid = connector && aModel && aModel.getter?(cid)
      @all_children.each { |child| child.updateModel(aModel, options) unless child.effectiveModel? }
      super
#       tag "DONE"
    end

    def columnCount value
#       tag "#{self}, value=#{value}, induce 'gridlayout'"
      check_layout(nil, :gridlayout).columnCount value
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

    # override
    def addWidget control, hash, &block
#       tag "#{self}, adding widget #{control}"
      if layout = infused_layout
#         tag "infused layout"
        control.containing_frame = layout
        layout.addWidget(control, hash, &block)
      else
        if @autolayout && layoutcreator = control.auto_layouthint
#           tag "create proper layout"
          check_layout(control, layoutcreator,  hash, &block)
        else
          super
        end
      end
    end

    def addLayout control, hash, &block
      if layout = infused_layout
        control.containing_frame = layout
        layout.addLayout(control, hash, &block)
      else
#           tag "#{self.class}::addControl. SETTING layout of #@qtc to #{control.qtc}"
        # Qt says the same but it's only a warning
        super # @qtc.layout = control.qtc
      end
    end

    # note that form has an override. Frames collect immediate controls.
    # Forms collect all controls, and they have an index too.
    def registerName aName, aControl
#       aName = aName.to_sym
#       define_singleton_method(aName) { aControl }  not really used anyway
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