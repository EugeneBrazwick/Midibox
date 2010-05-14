
module Reform

=begin rdoc
  Control instances are qtruby wrappers around the Qt elements.
  We extend QObject (Qt::Object) itself to enable slots and signals
=end
  class Control < Qt::Object
    private

    # create a new Control, using the frame as 'owner', and qtc as the wrapped Qt::Widget
    def initialize frame, qtc
#       tag "#{self}::initialize, caller=#{caller.join("\n")}"
      super()
      @containing_frame, @containing_form, @qtc, @has_pos = frame, frame.containing_form, qtc, false
    end

     # size QSize or size w,h, without args it returns qtc.size
    def size w = nil, h = nil
      return parent_qtc_to_use.size unless w
      if h
        @requested_size = w, h
        parent_qtc_to_use.resize w, h
      else
        @requested_size = w, w
        parent_qtc_to_use.resize w, w
      end
    end

    # geometry, set geo or return it.
    def geometry x = nil, y = nil, w = nil, h = nil
      return parent_qtc_to_use.geometry unless x or w
      @requested_size = w, h
      if x or y
        @has_pos = true
        parent_qtc_to_use.setGeometry x, y, w, h
      else
        parent_qtc_to_use.resize w, h
      end
    end

    # define a simple set method for each element passed, forwarding it to qtc.
    def self.define_simple_setter *list
      list.each do |name|
        define_method name do |value|
          @qtc.send(name.to_s + '=', value)
        end
      end
    end

    # default.
    def executeMacros
      instance_variable_defined?(:@macros) and @macros.each { |macro| macro.exec }
    end

    def name aName = nil
      return name unless aName
      @name = aName
      @containing_frame.registerName aName, self
    end

    # shortcut
    def timer_interval timeout_in_ms, &block
      start_timer(timeout_in_ms)
      whenTimeout(&block) if block
    end

    # default timeout event handler
    def whenTimeout &block
      @whenTimeout = block
    end

    def connect_id
      instance_variable_defined?(:@connect_id) ? @connect_id :
                                                 instance_variable_defined?(:@name) ? @name : nil
    end

    protected
    #override
    def timerEvent event
#       tag "timerEvent"
      return unless @whenTimeout
      @whenTimeout.call
    end

    # use this to wrap a rescue clause around any user-callback. Also
    # it calls the callback not in the object's context, but in that of the
    # form (MVC controller)
    def rfCallBlockBack *args, &block
      begin
        return containing_form.instance_exec(*args, &block)
      rescue LocalJumpError
         # ignore
      rescue IOError, RuntimeError => exception
        msg = "#{exception.message}\n"
      rescue StandardError => exception
        msg = "#{exception.class}: #{exception}\n" + exception.backtrace.join("\n")
      end
      # this must be fixed using an alert, but it may depend on the kind of exception...
      $stderr << msg
    end

    public
    # the parent widget (a Reform::Frame)
    attr :containing_frame

    # the owner form.
    attr :containing_form

    # Qt control that is wrapped
    attr :qtc

    # tuple w,h   as set in last call of setSize/setGeometry
    attr :requested_size

    def addWidget control, q
      @qtc.addWidget q
    end

    # return macros array, creating it if it was undefined
    # Macros are executed right after the setup block (if present)
    def macros!
      @macros ||= []
    end

    # was a position given
    def has_pos?
      @has_pos
    end

    # default resize callback setter/getter
    def whenResized &block
      return @whenResized unless block
      @whenResized = block
    end

    # normally the Qt implementor, but for layouts we add subcontrols to the
    # layouts owner. In other words, the result must be a Qt::Widget in all cases
    # which does not hold for all Controls.@qtc values.
    # Examples are Layout, Action and RSignalMapper.
    # Also, some subcontrols need 'nil' is their parent and this can be arranged
    # like this as well
    def parent_qtc_to_use
      @qtc
    end

    # this callback is called after the 'block' initialization. Or even without a block,
    # when the control is added to the parent and should have been setup.
    # can be used for postProc. Example: initialization parameters are stored and
    # executed in one go.  Note that postSetup should return self!
    # the default executes any gathered macro.
    def postSetup
#       tag "#{self}::postSetup"
      executeMacros
#       tag "DONE #{self}::postSetup"
      self
    end

    # qt_parent can be nil, but even then....
    # example, according to qt4 manual 'new Qt::GraphicsEllipseItem()' should be legal.
    # But qtruby thinks otherwise!
    # parent is never nil, and may very well be unfinised, later components may follow
    # called from instantiate_child
    def self.new_qt_implementor qt_implementor_class, parent, qt_parent
#       tag "#{qt_implementor_class}.new(#{qt_parent})"
      qt_implementor_class.new qt_parent
    end

    # called to instantiate a child, qparent is basicly the effective qtc.
    # this method can be overriden if child control has to be altered
    def instantiate_child(reform_class, qt_implementor_class, qparent)
      reform_class.new_qt_implementor(qt_implementor_class, self, qparent)
    end

    # widget -> bool.  Returns true if the control is a widget
    def widget?
    end

    # layout -> bool. Returns true if the control is a layout
    def layout?
    end

    def timer?
    end

    def graphic?
    end

    def model?
    end

=begin rdoc
    connect a model (may be nil) to the control
    The rules are as follows:
        - if the control has a connect_id (defaults to name) and that name is also
          a public method of model,
          with no arguments (a getter therefore) and if model is not nil, then we
          apply the method and use the result to set the value of the control.
        - otherwise if the control has no name, nor a connect_id set, it is left untouched,
          but the connect may propagate
        - otherwise the value of the control is cleared. The result must be 'clean'
        but validation may trigger if the user tries to 'commit' the formdata (clicks 'Update').
        - the specific value of nil stands for a nonset value. This could be automatically
        converted to 0 or an empty string, but the control must not treat the value as
        valid by default and validation must be triggered if the user attempts to 'commit'
        the formdata.
        - controls that can be changed should be protected if the accompanying setter is
        not available.
        - controls can set a @connect_id, that overrides @name.
        - if :initializing is set in 'options' the control must keep or set its 'clean'
        state, and must
        treat the field as being untouched by the user. In particular no triggers should be
        applied, and no validation should take place.
        - controls that have components must propagate the connection, even if they have no
        name.
        - if the value of a control does not change by the connect operation, no triggers must
        be called (at least not now).
   See Frame#connect
=end
    def connectModel model, options = nil
    end

  end # class Control

  # forward
  class Timer < Control
  end
end # Reform