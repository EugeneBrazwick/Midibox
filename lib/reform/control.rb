
#  Copyright (c) 2010 Eugene Brazwick

require 'reform/app'

class Fixnum
  def seconds
    Reform::Milliseconds.new(self * 1000)
  end

  alias :s :seconds

  def milliseconds
    Reform::Milliseconds.new(self)
  end

  alias :ms :milliseconds

end

module Reform

  class Milliseconds
    private
      def initialize val
        @val = val
      end
    public
      attr :val
      alias :value :val # required for Qt::Variant interaction etc/
  end

=begin rdoc
  Control instances are qtruby wrappers around the Qt elements.
  We extend QObject (Qt::Object) itself to enable slots and signals
=end
  class Control < Qt::Object
    private

      # create a new Control, using the frame as 'owner', and qtc as the wrapped Qt::Widget
      def initialize frame, qtc = nil
  #       tag "#{self}::initialize"
        if frame
  #         tag "calling Qt::Object.initialize(#{frame})"
          super(frame)
  #         tag "HERE"
              # self.parent = frame               Qt::Object constructor should do this!
  #         parent == frame or raise
        else
  #         tag "calling Qt::Object.initialize()"
          super()
  #         tag "HERE"
        end
  #       tag "HERE"
        # FIXME: each control has these and only qtc is of real importance
        # containing_form can be cached in the getter and has_pos needs not be set at all
        @containing_form, @qtc, @has_pos = frame && frame.containing_form, qtc, false
        @want_data = false
        # NOTE: parent may change to its definite value using 'added' See Frame::added
        # in all cases: c.parent.children.contains?(c)
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
      def geometry x = nil, y = nil, w = nil, h = nil, &block
        q = effective_qtc
        return q.geometry unless x || w || block
        case x
        when nil then DynamicAttribute.new(self, :geometry).setup(nil, &block)
        when Hash, Proc then DynamicAttribute.new(self, :geometry).setup(x, &block)
        else
          @requested_size = w, h
          if x or y
            @has_pos = true
            q.setGeometry x, y, w, h
          else
            q.resize w, h
          end
        end
      end

      # define a simple set method for each element passed, forwarding it to qtc.
      # using the same name plus '=' as the setter.
      def self.define_simple_setter *list
        list.each do |name|
          define_method name do |value = nil|
            return @qtc.send(name) if value.nil?
            @qtc.send(name.to_s + '=', value)
          end
        end
      end

  #     alias :def_simple_setter :define_simple_setter  DOES NOT WORK

      def executeMacros(receiver = nil)
#         tag "#{self}#executeMacros, EXECUTE #{instance_variable_defined?(:@macros) ? @macros.length : 0} macros"
        instance_variable_defined?(:@macros) and @macros.each do |macro|
#           tag "#{self}::Executing MACRO #{macro}"
          macro.exec(receiver)
        end
      end

      # a ruby scope instantiator that wraps around 'Qt::Object#blockSignals'.
      def no_signals
        old_blockSig = @qtc.blockSignals true
        begin
          yield
        ensure
          @qtc.blockSignals old_blockSig
        end
      end

      # shortcut. executes the block every ms milliseconds
      def timer_interval timeout_in_ms, &block
        start_timer(timeout_in_ms)
        whenTimeout(&block) if block
      end

      # default timeout event handler
      def whenTimeout &block
        @whenTimeout = block
      end

      # you should be able to set it too, and it can even be a block/proc(!!)
      # but BOTH a value and a block is not allowed. (?)
      def connector value = nil, &block
        if value || block
#           tag "setting connector, want_data!"
          @connector = block ? block : value
          want_data!
        else
          instance_variable_defined?(:@connector) && @connector
        end
      end

      def propagateModel aModel, propagation
#         tag "#{self}#propagateModel(#{aModel}, #{propagation.inspect}"
        # we keep clear of children with their own 'effective' models, which means that the
        # user parked a model in it explicitely.  But note it does not apply to internal models
        # like the combobox has (it is called 'model' confusingly...)
        if children
          children.each do |child|
#             tag "PROPCONDITIONS. child=#{child}, want_data?=#{Control === child && child.want_data?}"
            if Control === child && child.want_data?
              child_model = child.model?
#               tag "aModel=#{aModel}, child.model = #{child_model}"
              if !child_model || child_model != aModel
#                 tag "propagate"
                child.updateModel(aModel, propagation)
              end
            end
          end
        end
        whenConnected aModel, propagation # if connector
      end

      # data is the connector applied on the model. This is only called if we 'want data',
      # if we have a connector,
      # if the model has a getter for it, and
      # if the connector is in the 'changed' list of the propagation
      def applyModel data, model
      end

    protected

      def want_data!
#         tag "#{self}#want_data!, propagates up"
        unless @want_data
          @want_data = true
          # NOTE for dummies: 'parent' is a Qt Widget probably. So we must apply a hack here...
          # NOTE for bigger dummies: 'parent' is NOT a Qt Widget. WHY ?????
#           p = parent.instance_variable_get(:@_reform_hack) rescue nil
          if (p = parent).respond_to?(:want_data!)
            p.want_data!
          else
            tag "INFO: propagation of want_data! blocks at #{self}, parent #{p} lacks want_data!" unless ReForm === self
          end
        end
      end

      #override
      def timerEvent event
  #       tag "timerEvent"
        rfCallBlockBack(&@whenTimeout) if @whenTimeout
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

      def whenConnected model = nil, options = nil, &block
  #       tag "whenConnected, model=#{model}, block=#{block}, @whenConnected=#@whenConnected"
        if block
          want_data!
          @whenConnected = block
        else
          rfCallBlockBack(model, options, &@whenConnected) if instance_variable_defined?(:@whenConnected) && @whenConnected
        end
      end

      def added control
      end

      class Animation < Control

        private
          # our parent is the parent of the DynamicAttribute so it could be a GraphicsItem.
          # Which is a Qt::Object, even if Qt::GraphicsItem is not
          def initialize attrib
#             tag "Assigned attrib and propertyname '#{@qtc.propertyName}'"
          end

      end

=begin    # it may even be a very good idea to implement to 'enabler' and 'disabler' the very same way!
    # they are now kind of polluting the updateModel method.

      windowTitle { connector { |m| m.myTitle} }

      new DynamicAttribute self, :windowTitle, quicky, block
=end
      class DynamicAttribute < Control

        private

          def initialize parent, propertyname, quickyhash = nil, &block
#             tag "DynamicAttribute.new(#{parent}, :#{propertyname})"
            super(parent)
            @propertyname = propertyname
            setup(quickyhash, &block) if quickyhash || block
          end

          def through_state states2values
            form = containing_form
            setProperty('value', value2variant(:default))
            states2values.each do |state, value|
              form[state].qtc.assignProperty(self, 'value', value2variant(value))
            end
          end

          def animation quickyhash = nil, &block
            require_relative 'animations/attributeanimation'
#             tag "Creating Qt::Variant of value"
            setProperty('value', value2variant(:default))
#             tag ("calling Animation.new")
            AttributeAnimation.new(self, Qt::PropertyAnimation.new(self)).setup(quickyhash, &block)
          end

        public

          # override
          def event e
#             tag "#{self}.event(#{e})"
            case e
            when Qt::DynamicPropertyChangeEvent
              # we may expect the value to be 'value'
              raise "unexpected property '#{e.propertyName}'" unless e.propertyName == 'value'
              val = property('value').value
              tag "applyModel(#{val.inspect})"
              applyModel val
#             else
#               tag "unhandled .... #{self}.event(#{e})"
            end
#             super  not much use
          end

          def value2variant *value
            case @propertyname
            when :brush
              color = Graphical.color(*value)
#               tag "Qt::Variant.new(#{color})"
              Qt::Variant::fromValue(color)
            when :geometry
              Qt::Variant::fromValue(case value[0]
              when :default then Qt::Rect.new
              when Qt::Rect then value[0]
              else Qt::Rect.new(*value) #.tap{|r| tag "creating value(#{r.inspect})"}
              end)
            when :geometryF
              Qt::Variant::fromValue(case value[0]
              when :default then Qt::RectF.new
              when Qt::RectF then value[0]
              else Qt::RectF.new(*value) #.tap{|r| tag "creating value(#{r.inspect})"}
              end)
            else
              raise Error, tr("Not implemented: animation for property '#@propertyname'")
            end
          end

          # called when Qt::DynamicPropertyChangeEvent is received
          def applyModel data, model = nil
            tag "#{parent}.#@propertyname := #{data.inspect}"
            parent.send(@propertyname.to_s + '=', data)
          end

          # the result is a symbol
          attr :propertyname, :animprop

          alias :propertyName :propertyname

#           attr_accessor  :value

#           properties 'value'

      end # class DynamicAttribute

      DynamicProperty = DynamicAttribute

    public

      attr_writer :connector

      def want_data?
        @want_data
      end

      # the owner form.
      attr :containing_form

      # Qt control that is wrapped
      attr :qtc

      # tuple w,h   as set in last call of setSize/setGeometry
      attr :requested_size

      # an Array of macros,   we may need a separate index for named macros but
      # I forgot what needed that. Probably broken now.
      attr :macros

=begin  **************** PARENTING SYSTEM *********************************

      1) a single method 'addTo'. This calls the proper 'addition' callback
            addWidget
            addLayout
            addMenu
            addAction
            addModel
            addAnimation
            addState
        these methods must setup the control too as the order differs sometimes

      2) which parent_qtc to use? This also depends on the child to be added and on the parent

=end
      def addTo parent, quickyhash = nil, &initblock
        raise ReformError, tr("Don't know how to add a %s to a #{parent.class}") % self.class
      end

          # If we are going to parent a 'reform_class' which qtc to use.
      # The result must be a Qt::Widget in all cases
      # Also, some subcontrols need 'nil' as their parent and this can be arranged
      # like this as well. By default we use effective_qtc, since it it about the same thing.
      # IMPORTANT: the argument is the class!
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
      def setup hash = nil, &initblock
        instance_eval(&initblock) if initblock
        setupQuickyhash(hash) if hash
        postSetup
        self
      end

=begin
      add to parent + setup and finally postSetup. This is in the end how
      instantiator { block }  or instantiator hash
      is added to the current element (parent).
      It calls one of the addXXXX methods back (based on what is added) and so
      we proceed.
=end
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

      def addScene control, hash, &block
        # ONLY a canvas can set the scene
#         @qtc.scene = control.qtc
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

      def addAnimation control, quickyhash = nil, &block
        control.parent = self
        control.setup quickyhash, &block
        added control
      end

      def addState control, quickyhash = nil, &block
        control.parent = self
        control.setup quickyhash, &block
        added control
      end

  #     def addSeparator control, hash, &block
  #       @qtc.addSeparator
  #           # added control  not usefull
  #     end

      def addModel control, hash, &block
        @model ||= nil
        control.setup hash, &block
#         want_data!            this is a toplevel call. There is no need to do this.
# and it wrong for comboboxes or lists that are assigned local data.
        unless @model.equal? control
          @model.removeObserver_i(self) if @model
          @model = control
          @model.addObserver_i(self) if @model
        end
        added control
      end

      def setupQuickyhash hash
#         tag "#{self}.setupQuickyhash(#{hash.inspect})"
        hash.each do |k, v|
#           tag "#{self}.#{k}(#{v})"
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

      def name aSymbol = nil
        if aSymbol
  #       tag "#{self}::assigning objectname #{aName}"
          self.objectName = @qtc.objectName = aSymbol.to_s
        # there is a slight duplication but the qt windowtree differs.
        # for example, a layout can have named children in 'reform' but not in Qt.
  #         tag "calling #parent.registerName(#{aName})"
          parent.registerName aSymbol, self
        else
  #         raise "#{self} has no @qtc. SHINE!" unless @qtc               Spacer has no Qt complement, maybe more
          objectName.to_sym
        end
      end

      # note that form has an override. Frames collect immediate controls.
      # Forms collect all controls, and they have an index too.
      def registerName aName, aControl
  #       aName = aName.to_sym
  #       define_singleton_method(aName) { aControl }  not really used anyway
        containing_form.registerName(aName, aControl)
      end

      # sets it if block is given, or calls it, if w,h is given, otherwise returns the handler itself
      # that last feature is never used anymore.
      def whenResized(w = nil, h = nil, &block)
        if block
          @whenResized = block
        else
          return @whenResized if w.nil?
          if instance_variable_defined?(:@whenResized)
            rfCallBlockBack(w, h, &@whenResized)
          end
        end
      end

      # this callback is called after the 'block' initialization. Or even without a block,
      # when the control is added to the parent and should have been setup.
      # can be used for postProc. Example: initialization parameters are stored and
      # executed in one go.
      # the default executes any gathered macro. So you should call this first
      def postSetup
#         tag "#{self}#postSetup, model=#@model"
        executeMacros
        if instance_variable_defined?(:@model)
#           tag "start model propagation"
          require 'reform/model'
          updateModel(@model, Propagation.new(self, nil, true))
        end
      end

      # qt_parent can be nil, but even then....
      # example, according to qt4 manual 'new Qt::GraphicsEllipseItem()' should be legal.
      # But qtruby thinks otherwise!
      # parent is never nil, and may very well be unfinised, later components may follow
      # called from instantiate_child
      def self.new_qt_implementor qt_implementor_class, parent, qt_parent
#         tag "#{qt_implementor_class}.new(#{qt_parent})"
        qt_implementor_class.new qt_parent
      rescue ArgumentError=>e
        raise ArgumentError, "#{qt_implementor_class}.new(#{qt_parent}): #{e}"
      end

      # called to instantiate a child, qparent is basicly the effective qtc.
      # this method can be overriden if child control has to be altered
      def instantiate_child(reform_class, qt_implementor_class, qparent)
#         tag "#{self}::instantiate_child(impl=#{qt_implementor_class}, qparent=#{qparent})"
        reform_class.new_qt_implementor(qt_implementor_class, self, qparent)
      end

      # widget -> bool.  Returns true if the control is a widget.
      # Required because some things (like scene) inherit Widget but are realy no widgets
      def widget?
      end

      # layout -> bool. Returns true if the control is a layout  Better use Layout === x
      def layout?
      end

        # better use AbstractAction === x.
      def action?
      end

      # may return nil or a layout instantiator symbol (like :formlayout, :hbox, :vbox)
      def auto_layouthint
        # labeledwidget takes formlayout, which makes sense.
        # If I pass nil back the form will add the widget as is, and the result is pretty
        # terrible.
        :vbox
      end

=begin rdoc
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
=end
      def updateModel aModel, propagation
#         tag "#{self}::updateModel(#{aModel}, #{propagation.inspect}), connector=#{connector}"
        if (cid = connector) && propagation.sender != self && propagation.changed?(cid)
    #           tag "apply cid #{cid} on model #{mod}"
    #           tag "DynamicAttribute activated: #{parent}.#@propertyname := #{mod.apply_getter(cid)}"

          applyModel aModel.apply_getter(cid), aModel
        end
        propagateModel aModel, propagation
      end

      # return the model of the containing frame or form, traveling upwards until one is found.
      def effectiveModel
        parent.effectiveModel
      end

      # true if model is set on this control. Can only be true for forms or frames
      def effectiveModel?
      end

      def frame_ex
        if Frame === self then self else parent.frame_ex end
      end

      # as a replacement for findChildren. Note that klass is a Reform class!
      # it works recursively.
      # However, it also enumerates itself, if the condition applies.
      def find klass = nil, name = nil, &block
        return to_enum(:find, klass, name) unless block
        if (!klass || klass === self) && (!name || name === @qtc.name)
#           tag "find, klass=#{klass}, #{self} is a #{klass}, req. name = #{name}. Calling block!"
          block[self]
        end
        children.tap{ |chlds| chlds and chlds.each { |child| Control === child and child.find(klass, name, &block) } }
      end

      alias :findChildren :find

      # can be used as a bool too.
      def model?
        instance_variable_defined?(:@model) ? @model : nil
      end

      def geometry=(*value)
        @qtc.geometry = *value
      end
  end # class Control

end # Reform