
#  Copyright (c) 2010 Eugene Brazwick

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
      @containing_frame, @containing_form, @qtc, @has_pos = frame, frame && frame.containing_form, qtc, false
      # to be set to true when signals are connected to module-setters.
      # however, it should be possible to do this when :initialize is set in options of
      # connectModel.
#       @connected = false
    end

#     def blockSignals val = true
#       @qtc.blockSignals = val
#     end

     # size QSize or size w,h, without args it returns qtc.size
    def size w = nil, h = nil
      q = effective_qtc
      return q.size unless w
      if h
        @requested_size = w, h
        q.resize w, h
      else
        @requested_size = w, w
        q.resize w, w
      end
    end

    # geometry, set geo or return it.
    def geometry x = nil, y = nil, w = nil, h = nil
      q = effective_qtc
      return q.geometry unless x or w
      @requested_size = w, h
      if x or y
        @has_pos = true
        q.setGeometry x, y, w, h
      else
        q.resize w, h
      end
    end

    # define a simple set method for each element passed, forwarding it to qtc.
    def self.define_simple_setter *list
      list.each do |name|
        define_method name do |value = nil|
	  return @qtc.send(name) if value.nil?
          @qtc.send(name.to_s + '=', value)
        end
      end
    end

    # default.
    def executeMacros
      instance_variable_defined?(:@macros) and @macros.each do |macro|
#         tag "#{self}::Executing MACRO #{macro}"
        macro.exec
      end
    end

    def no_signals
      old_blockSig = @qtc.blockSignals true
      begin
        yield
      ensure
        @qtc.blockSignals old_blockSig
      end
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

    # you should be able to set it too, and it can even be a block/proc(!!)
    def connector value = nil
      if value.nil?
        return @connector if instance_variable_defined?(:@connector)
	@connector = @qtc.objectName
#         tag "#{self}, default connector == 'name' -> #@connector"
	case @connector
	when /Edit$|Combo$|Form$|Button$|Label$|List$|Table$/
          tag "'#@connector' matches standard ctrl name, fixing -> #{$`}"
          @connector = $`
        else
          @connector
	end
      else
        @connector = value
      end
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
#         tag "rfCallBlockBack, block=#{block.inspect}"
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

    def whenConnected model = nil, &block
#       tag "whenConnected, model=#{model}, block=#{block}, @whenConnected=#@whenConnected"
      if block
        @whenConnected = block
      else
        rfCallBlockBack(model, &@whenConnected) if instance_variable_defined?(:@whenConnected)
      end
    end

    # basemethod, called from connectModel (from setModel)
    def model *data
    end

    public
    # the parent frame (a Reform::Frame), can be widget or layout
    attr_accessor :containing_frame

    # the owner form.
    attr :containing_form

    # Qt control that is wrapped
    attr :qtc

    # tuple w,h   as set in last call of setSize/setGeometry
    attr :requested_size

    def addWidget control, q
#       tag "#{self.class}::addWidget(#{control.class}, #{q.class}) -> DELEGATE to #{@qtc.class}"
      if control.layout?
        @qtc.addLayout q
      else
        @qtc.addWidget q
      end
#       tag "added widget"
    end

    def setupQuickyhash hash
      hash.each do |k, v|
#         tag "#{k}(#{v})"
        send(k, v)
      end
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

    def name aName = nil
      if aName
#       tag "#{self}::assigning objectname #{aName}"
        @qtc.objectName = aName
      # there is a slight duplication but the qt windowtree differs.
      # for example, a layout can have named children in 'reform' but not in Qt.
        @containing_frame.registerName aName, self
      else
#         raise "#{self} has no @qtc. SHINE!" unless @qtc               Spacer has no Qt complement, maybe more
        @qtc && @qtc.objectName
      end
    end

    # default resize callback setter/getter
    def whenResized &block
      return rfCallBlockBack(&@whenResized) unless block
      @whenResized = block
    end

    # If we are going to parent a 'reform_class' which qtc to use.
    # The result must be a Qt::Widget in all cases
    # Also, some subcontrols need 'nil' as their parent and this can be arranged
    # like this as well. By default we use effective_qtc, since it it about the same thing.
    def parent_qtc_to_use_for(reform_class)
      reform_class <= Layout ? nil : effective_qtc
    end

    # The result must be a Qt::Widget in all cases.
    #
    def effective_qtc
      @qtc
    end

    # this callback is called after the 'block' initialization. Or even without a block,
    # when the control is added to the parent and should have been setup.
    # can be used for postProc. Example: initialization parameters are stored and
    # executed in one go.
    # the default executes any gathered macro.
    def postSetup
#       tag "#{self}::postSetup"
      executeMacros
#       tag "DONE #{self}::postSetup"
#       self  BOGO CODE
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
# #       tag "#{self}::instantiate_child(impl=#{qt_implementor_class}, qparent=#{qparent})"
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

    # may return nil or a layout instantiator symbol (like :formlayout, :hbox, :vbox)
    def auto_layouthint
    end

=begin rdoc
    connect a model (may be nil) to the control
    The rules are as follows:
        - if the control has a connector (defaults to name) and that name is also
          a public method of model,
          with no arguments (a getter therefore) and if model is not nil, then we
          apply the method and use the result to set the value of the control.
        - otherwise if the control has no name, nor a connector set, it is left untouched,
          but the connect may propagate
        - otherwise the value of the control is cleared. The result must be 'clean'
        but validation may trigger if the user tries to 'commit' the formdata (clicks 'Update').
        - the specific value of nil stands for a nonset value. This could be automatically
        converted to 0 or an empty string, but the control must not treat the value as
        valid by default and validation must be triggered if the user attempts to 'commit'
        the formdata.
        - controls that can be changed should be protected if the accompanying setter is
        not available.
        - controls can set a @connector, that overrides @name.
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
    def connectModel aModel, options = nil
#       tag "#{self}, aModel=#{aModel}, should be propagated!"
#       @model ||= nil
#       unless @model.equal?(aModel)
#         @model.removeObserver_i(self) if @model
  #         @model.containing_form = @containing_form
#         aModel.addObserver_i(self) if aModel
  #         model aModel ?????????
#         @model = aModel
#       end
      whenConnected aModel
    end

    def effectiveModel
      @containing_frame.effectiveModel
    end

    # true if model is set on this control. Can only be true for forms or frames
    def effectiveModel?
    end

     # set a new model
    def setModel aModel, quickyhash = nil, &initblock
#       tag "#{self}::setModel(#{aModel}, quickargs=#{quickyhash.inspect})"
      aModel.instance_eval(&initblock) if initblock
      aModel.setupQuickyhash(quickyhash) if quickyhash
      aModel.postSetup
#       tag "Calling connectModel"
      connectModel(aModel, initialize: true) # if instance_variable_defined?(:@model)
    end

  end # class Control

  # forward
  class Timer < Control
  end
end # Reform