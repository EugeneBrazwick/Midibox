
#  Copyright (c) 2010 Eugene Brazwick

module Reform

=begin rdoc
  Control instances are qtruby wrappers around the Qt elements.
  We extend QObject (Qt::Object) itself to enable slots and signals
=end
  class Control < Qt::Object
    private

    # create a new Control, using the frame as 'owner', and qtc as the wrapped Qt::Widget
    def initialize frame, qtc = nil
#       tag "#{self}::initialize, caller=#{caller.join("\n")}"
      if frame
        super(frame)
      else
        super()
      end
      parent = frame
      @containing_form, @qtc, @has_pos = frame && frame.containing_form, qtc, false
      # NOTE: parent may change to its definite value using 'added' See Frame::added
      # in all cases: c.parent.children.contains?(c)
      # to be set to true when signals are connected to module-setters.
      # however, it should be possible to do this when :initialize is set in options of
      # updateModel.
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
    # in fact it also adds the getter... urm...
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
    def connector value = nil, &block
      if value.nil? && !block
        return @connector if instance_variable_defined?(:@connector)
	@connector = @qtc.objectName
#         tag "#{self}, default connector == 'name' -> #@connector"
	case @connector
	when /Edit$|Combo$|Form$|Button$|Label$|List$|Table$|Box$|Action$|Menu$|Group$/
#           tag "'#@connector' matches standard ctrl name, fixing -> #{$`}"
          @connector = $`
        else
          @connector
	end
      else
        @connector = block ? block : value
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
#       tag "rfCallBlockBack #{block}, caller=#{caller.join("\n")}"
#       raise unless block
      rfRescue do
          # RETURN is deadly!!!!!??????????
#         tag "rfCallBlockBack, block=#{block.inspect}"
        return containing_form.instance_exec(*args, &block)
      end
    end

    def whenConnected model = nil, &block
#       tag "whenConnected, model=#{model}, block=#{block}, @whenConnected=#@whenConnected"
      if block
        @whenConnected = block
      else
        rfCallBlockBack(model, &@whenConnected) if instance_variable_defined?(:@whenConnected) && @whenConnected
      end
    end

    def added control
    end

    public

    attr_writer :connector

    # the owner form.
    attr :containing_form

    # Qt control that is wrapped
    attr :qtc

    # tuple w,h   as set in last call of setSize/setGeometry
    attr :requested_size

=begin  **************** PARENTING SYSTEM *********************************

    1) a single method 'addTo'. This calls the proper 'addition' callback
          addWidget
          addLayout
          addMenu
          addAction
          addModel
      these methods must setup the control too as the order differs sometimes

    2) which parent_qtc to use? This also depends on the child to be added and on the parent

=end

    def addTo parent, quickyhash = nil, &initblock
      raise ReformError, tr("Don't know how to add a %s") % self.class
    end

        # If we are going to parent a 'reform_class' which qtc to use.
    # The result must be a Qt::Widget in all cases
    # Also, some subcontrols need 'nil' as their parent and this can be arranged
    # like this as well. By default we use effective_qtc, since it it about the same thing.
    def parent_qtc_to_use_for reform_class
      #reform_class.respond_to?(:parent_qtc) &&
      reform_class.parent_qtc(self, effective_qtc)
    end

    # If self is the class of the child, which qtc to use as parent
    def self.parent_qtc parent_control, parent_effective_qtc
      parent_effective_qtc
    end

    # specific case if we are to parent an action
    def effective_qtc_for_action
      containing_form.qtc
    end

    # The result must be a Qt::Widget in all cases.
    def effective_qtc
      @qtc
    end

    # called when control was added to parent, except for models
    def setup hash, &initblock
      instance_eval(&initblock) if initblock
      setupQuickyhash(hash) if hash
      postSetup
    end

    def add child, quickyhash, &block
      child.addTo(self, quickyhash, &block)
#       added child
    end

    # also this only does something with the qt hierarchie
    # Normally 'q' will be control.qtc
    def addWidget control, hash, &block
#       tag "#@qtc.addWidget(#{control.qtc})"
      @qtc.addWidget control.qtc if @qtc
      control.setup hash, &block
      added control
    end

    def addLayout control, hash, &block
      raise "#{self} '#{name}' already has #{@qtc.layout} '#{@qtc.layout.objectName}'!" if @qtc.layout
      @qtc.layout = control.qtc
      control.setup hash, &block
      added control
    end

    def addMenu control, hash, &block
      raise "#{self} '#{name}' already has #{@qtc.menu} '#{@qtc.menu.objectName}'!" if @qtc.menu
      @qtc.menu = control.qtc
      control.setup hash, &block
      added control
    end

    def addAction control, hash = nil, &block
#       tag "#@qtc.addAction(#{control.qtc})"
      @qtc.addAction control.qtc
      control.setup hash, &block
#       tag "added action #{control} to parent #{parent}"
      added control
    end

#     def addSeparator control, hash, &block
#       @qtc.addSeparator
#           # added control  not usefull
#     end

    def addModel control, hash, &block
      @model ||= nil
      control.setup hash, &block
      unless @model.equal? control
        @model.removeObserver_i(self) if @model
        @model = control
        @model.addObserver_i(self) if @model
      end
      added control
    end

    def setupQuickyhash hash
      hash.each do |k, v|
#         tag "#{k}(#{v})"
        send(k, v) unless k == :postSetup || k == :qtparent # and other hacks!!
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
#         tag "calling #parent.registerName(#{aName})"
        parent.registerName aName, self
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

    # this callback is called after the 'block' initialization. Or even without a block,
    # when the control is added to the parent and should have been setup.
    # can be used for postProc. Example: initialization parameters are stored and
    # executed in one go.
    # the default executes any gathered macro.
    def postSetup
#       tag "#{self}::postSetup, model=#@model"
      executeMacros
      updateModel @model, initialize: true if @model
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

    def menu?
    end

    def action?
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
    def updateModel aModel, options = nil
      tag "#{self}, aModel=#{aModel}, should be propagated!"
#       @model ||= nil
#       unless @model.equal?(aModel)
#         @model.removeObserver_i(self) if @model
  #         @model.containing_form = @containing_form
#         aModel.addObserver_i(self) if aModel
  #         model aModel ?????????
#         @model = aModel
#       end
      whenConnected aModel # if connector
    end

    def effectiveModel
      parent.effectiveModel
    end

    # true if model is set on this control. Can only be true for forms or frames
    def effectiveModel?
    end

  end # class Control

  # forward
  class Timer < Control
  end
end # Reform