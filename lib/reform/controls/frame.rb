
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

=begin rdoc
    connect a model (may be nil) to the frame.
    The rules are as follows:
        - if the frame has a connect_id and that name is also a public method of model,
          with no arguments (a getter therefore) and if model is not nil, then we
          apply the method and use the result to propagate to each control that
          is a direct child
        - if the frame has no name, or basically any other case then the first,
          it will take no action by itself,
          but the connect propagates to each control that is a direct child
=end
    def connectModel model, options = nil
#       tag "connecting model"
      if cid = connect_id && model && model.getter?(cid)
        model = model.send(cid)
      end
      for widget in @all_widgets
        widget.connectModel model, options
      end
    end

    # does NOT add the control for Qt !!!, but it does so for layouts ??
    # it returns the added control
    def addControl control, &block
#       tag "#{self.class}::addControl(#{control})"
      if control.widget?
        @all_widgets << control
      elsif control.layout?
        @qtc.layout = control.qtc
#       else
#         case control
#         when Timer then control.qtc.start
#         end
      end
      control.instance_eval(&block) if block
      control.postSetup
    end

    def registerName aName, aControl
#       tag "registerName(#{aName}, #{aControl})"
#       tag "DEFINE: #{self}::#{aName} -> #{aControl}"
      define_singleton_method(aName) { aControl }
      # not @containing_form: (!)
#       tag "containing_form=#{containing_form}, self=#{self}"
      unless containing_form == self
#         tag "DEFINE: #@form::#{aName} -> #{aControl}"
        containing_form.define_singleton_method(aName) { aControl }
      end
    end

  end # class Frame

  QForm = QWidget # good enough

  createInstantiator File.basename(__FILE__, '.rb'), QForm, Frame

end # Reform