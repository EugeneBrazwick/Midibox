
#  Copyright (c) 2010 Eugene Brazwick

#       equire 'reform/app'             VERY BAD IDEA

module Reform

# Control instances are reform wrappers around the Qt(ruby) elements.
# We extend QObject (Qt::Object) itself to enable slots and signals
# Since all setup blocks are executed in the context of the item being
# setup, most property setters can be private.
# This means that private methods are rather important
#
# Events are received back in our objects through some largescale hacking
# All event callbacks start with the text 'when'. And the callback is always
# executed in the context of the form.
#
# === Connects
# Something about the connect call.
#
# Since Control is a Qt::Object you can connect its signals to slots. Or other controls signals to procs.
# But you should be careful to do this only once, for example in the constructor(initialize).
# The reason is that Qt stacks all connections on top of each other. They do not replace previous connections.
# The proper setup is this:
#
#       class MyControl
#         def initialize ...
#           connect(@qtc, SIGNAL('oops()')) do
#             rfCallBlockBack(@whenOops) if instance_variable_defined?(:@whenOops)
#           end
#         end
#
#         def whenOops &block
#           @whenOops = block
#         end
#
# And you can replace the callback '@whenOops' any time you like.
#
  class Control < Qt::Object

      class Animation < Control

        private # Animation methods
          # our parent is the parent of the DynamicAttribute so it could be a GraphicsItem.
          # Which is a Qt::Object, even if Qt::GraphicsItem is not
          def initialize attrib
#             tag "Assigned attrib and propertyname '#{@qtc.propertyName}'"
          end

      end


    private # Control methods

      # create a new Control, using the frame as 'owner', and qtc as the wrapped Qt::Widget
      def initialize parent = nil, qtc = nil
  #       tag "#{self}::initialize"
        if parent
#           tag "calling Qt::Object.initialize(#{parent})"
          super(parent)
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
        @containing_form, @qtc = parent && parent.containing_form, qtc
        @qtc.instance_variable_set(:@_reform_hack, self) if @qtc

        # true if a connector is on this control, or on any of its children
#         @want_data = false                    leave it unset (effectively false)

        # the connected or set model. model.root.parent is the original container. This is a Model
#         @model = nil

        # NOTE: parent may change to its definite value using 'added' See Frame::added
        # in all cases: c.parent.children.contains?(c)
      end

      # a parameter block can be declared using the block. It actually is a macro.
      # a parameter block can be executed by omitting the block
      def parameters id, quicky = nil, &block
        if block
          containing_form.parametermacros[id] = Macro.new(nil, nil, quicky, block)       # bit heavy
        else
#           tag "executing macroblock :#{id} on #{self}"
          macro = containing_form.parametermacros[id] and
            setup(macro.quicky, &macro.block)
        end
      end

      # it returns qtc.size
      # use sizeHint to set a requested size
      def size # w = nil, h = nil
        effective_qwidget.size
#         return q.size unless w
#         tag "better use
#         if h
#           @requested_size = w, h
#           q.resize w, h
#         else
#           @requested_size = w, w
#           q.resize w, w
#         end
      end

      # geometry, set geo, return it or instantiate a dynamic property or animation
      def geometry x = nil, y = nil, w = nil, h = nil, &block
        q = effective_qwidget
        return q.geometry unless x || w || block
        case x
        when nil, Hash, Proc then DynamicAttribute.new(self, :geometry, Qt::Rect).setup(x, &block)
        else
#           @requested_size = w, h
          if x or y
            @has_pos = true
            q.setGeometry x, y, w, h
          else
            q.resize w, h
          end
        end
      end

      # define a simple set method for each element passed, forwarding it to qtc.
      # using the same name plus '=' as the setter. Also it creates the getter
      # (which is the same method in the 'reform' system)
      # Example:
      #
      #         define_simple_setter :prop
      #
      # will basicly create:
      #
      #         def prop value = nil
      #           return @qtc.prop if value.nil?
      #           @qtc.prop = value
      #         end
      #
      def self.define_simple_setter *list
        list.each do |name|
          n = (name.to_s + '=').to_sym
          define_method name do |value = nil|
            return @qtc.send(name) if value.nil?
            @qtc.send(n, value)
          end
        end
      end

      # create a DynamicAttribute for each element in the list.
      # the first parameter is the kind of value, and must be an animatable value
      # defines two methods. A specific setter method is also created.
      # since the protectionlevel is not set, they will both use the current one.
      # So 'private ; ... define_setter '  will create two private methods.
      # Boolean and TrueClass are the same and have defaultvalue 'true', while
      # FalseClass has a default of 'false'. Numerics have 0 as default.
      def self.define_setter klass, *list
        list.each do |name|
          n = (name.to_s + '=').to_sym
          define_method name do |*args, &block|
#             tag "DynamicAttribSetter :#{name}, args=#{args.inspect}, block = #{block}"
            return @qtc.send(name) if args.empty? && !block
#             tag "args[0] is a #{args[0].class}"
            case args[0]
            when Hash, Proc, nil
              DynamicAttribute.new(self, name, klass, args[0], &block)
#               tag "created DA, value -> #{value}"
#               @qtc.send(n, value)             NO. data must come from outside.
            else @qtc.send(n, *args)
            end
          end # method name
          define_method n do |value|
#             tag "assigning dynamic result #{value.inspect}"
            @qtc.send(n, value)
          end # method name=
        end
      end # define_setter

      #         alias :define_dynamic_setter :define_setter             CANT BE DONE EASILY WITH static methods...

      def executeMacros(receiver = nil)
#         tag "#{self}#executeMacros, EXECUTE #{instance_variable_defined?(:@macros) && @macros.length} macros"
        instance_variable_defined?(:@macros) and @macros.each do |macro|
#           tag "#{self}::Executing MACRO #{macro}"
          macro.exec(receiver)
        end
#         tag "HERE"
      end

      # return true if applyModel should be called.
      def check_propagation_change propagation, cid
        propagation.get_change(cid)
      end

      # a ruby scope instantiator that wraps around 'Qt::Object#blockSignals'.
      # Within the block all Qt signals are suppressed
      def no_signals
        old_blockSig = @qtc.blockSignals true
        begin
          yield
        ensure
          @qtc.blockSignals old_blockSig
        end
      end

      def debug level
        old = Qt::debug_level
        Qt::debug_level = level
        yield
      ensure
        Qt::debug_level = old
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

      # This very important method ties the object in the reform model propagation
      # system. The connector is normally the name (symbol) of a getter method of the model.
      # When the model propagates this getter is applied to the model and the result is
      # used to show it.
      # The _connector_ can also be a proc which is then applied to the model as the getter,
      # and the result from the block is used.
      # What the control does with the supplied data is up to itself.
      # Example:
      #
      #          Reform::app {
      #            ruby_model name: 'johnny'
      #            edit {
      #              connector :name
      #            }
      #
      # The contents of the edit will be 'johnny' and if changed, this change will propagate through the
      # entire form (or other forms as well).
      # An equivalent connector would be:
      #
      #              connector { |data| data.name }
      #
      # Connectors will not work on all controls, but they should work as 'expected'.
      #
      # To make a working clock with 'reform' you can say:
      #
      #          Reform::app {
      #            timer
      #            edit connector: current
      #          }
      #
      # BANG! A clock.
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
#         if children
          children.each do |child|
            # you can switch on tracking propagations by marking the transaction (tran.debug_track!)
            # or by passing debug_track: true as arg4 of 'apply_setter'
            if propagation.debug_track?
              STDERR.print "#{self}::propagateModel child=#{child}, want_data?=#{Control === child && child.want_data?}\n"
            end
            child.updateModel(aModel, propagation) if Control === child && child.want_data?
          end
#         end
      end

      # data is the connector applied on the model. This is only called if we 'want data',
      # if we have a connector,
      # if the model has a getter for it, and
      # if the connector is in the 'changed' list of the propagation
      def applyModel data
      end

    protected # Control methods

      def want_data!
#         tag "#{self}#want_data!, propagates up (with a bit of luck)"
        unless want_data?
          @want_data = true
          # NOTE for dummies: 'parent' is a Qt Widget probably. So we must apply a hack here...
          # NOTE for bigger dummies: 'parent' is NOT a Qt Widget. WHY ?????
#           p = parent.instance_variable_get(:@_reform_hack) rescue nil
#           tag "parent is a #{parent.class}"
          if (p = parent) && p.respond_to?(:want_data!)
            p.want_data!
          else # this can only happen if the parent is no Control. Expected for ReForm since they have no parent.
            unless ReForm === self
              STDERR.print "INFO: propagation of want_data! blocks at #{self}, parent #{p} lacks 'want_data!'\n"
            end
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
          begin
            return containing_form.instance_exec(*args, &block)
          rescue LocalJumpError
            # utterly ignore it. It is caused because the block did a return or break itself.
            # This is basicly illegal as our block has lost its original context
          end
        end
      end

      def whenConnected model = nil, propagation = nil, &block
  #       tag "whenConnected, model=#{model}, block=#{block}, @whenConnected=#@whenConnected"
        if block
          want_data!
          @whenConnected = block
        else
            # if whenConnected is set, it should be a block since there is no way to unset it.
          rfCallBlockBack(model, propagation, &@whenConnected) if instance_variable_defined?(:@whenConnected)
        end
      end

      def added control
      end

    public # Control methods

      def track_propagation v = nil
        return @debug_track if v.nil?
        tag "#{self}::debug_track := #{v}"
        @debug_track = v
      end

      # Once a control sets a connector it then returns true here, and so will
      # all its parents, up to (but excluding) the containing form.
      # this is used when propagating modelchanges to easily skip controls
      # that have no interest in any changes.
      def want_data?
        instance_variable_defined?(:@want_data) && @want_data
      end

#       def parent val = nil
#         return super() unless val
#         setParent(val)
#       end

      # tuple w,h   as set in last call of setSize/setGeometry
#       attr :requested_size

=begin  **************** PARENTING SYSTEM *********************************

      1) a single method 'addTo'. This calls the proper 'addition' callback
            addWidget
            addLayout
            addMenu
            addAction
            addModel
            addAnimation
            addState
            addDockWidget
            addToolbar
            etc. etc.
        these methods must setup the control too as the order differs sometimes

      2) which parent_qtc to use? This also depends on the child to be added and on the parent

=end
      def addTo parent, quickyhash = nil, &initblock
        raise ReformError, tr("Don't know how to add a %s to a #{parent.class}") % self.class
      end

      # If we are going to parent a 'reform_class' which qtc to use.
      # Some subcontrols need 'nil' as their parent and this can be arranged
      # like this as well. By default we use effective_qwidget, since it it about the same thing.
      # IMPORTANT: the argument is the class, not an instance!
      def parent_qtc_to_use_for reform_class
        #reform_class.respond_to?(:parent_qtc) &&
        reform_class.parent_qtc(self, effective_qwidget)
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
      # only layouts currently override this
      def effective_qwidget
        @qtc
      end

      # called when control was added to parent, except for models.
      # here we 'execute' the block or the hash, whichever was given
      # and then we call postSetup
      def setup hash = nil, &initblock
        rfRescue do
          instance_eval(&initblock) if initblock
          setupQuickyhash(hash) if hash
          postSetup
        end
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
#         tag "Calling #{child}::addTo, child.public_methods = #{child.public_methods.inspect}"
        raise "an idiot is trying to add nil as child!" unless child
        child.addTo(self, quickyhash, &block)
  #       added child
      end

      # :nodoc:
      def addWidget control, hash, &block
  #       tag "#@qtc.addWidget(#{control.qtc})"
        @qtc.addWidget control.qtc if @qtc
        control.setup hash, &block
        added control
      end

      # :nodoc: called by +add+ if the control was a scene
      def addScene control, hash, &block
        # ONLY a canvas can set the scene
#         @qtc.scene = control.qtc
        control.setup hash, &block
        added control
      end

      # :nodoc: called by +add+ if the control was a layout
      def addLayout control, hash, &block
        raise "#{self} '#{name}' already has #{@qtc.layout} '#{@qtc.layout.objectName}'!" if @qtc.layout
        @qtc.layout = control.qtc
        control.setup hash, &block
        added control
      end

      # :nodoc: called by +add+ if the control was a menu
      def addMenu control, hash, &block
        raise "#{self} '#{name}' already has #{@qtc.menu} '#{@qtc.menu.objectName}'!" if @qtc.menu
        @qtc.menu = control.qtc
        control.setup hash, &block
        added control
      end

      # :nodoc: called by +add+ if the control was an action
      def addAction control, hash = nil, &block
  #       tag "#@qtc.addAction(#{control.qtc})"
        @qtc.addAction control.qtc
        control.setup hash, &block
  #       tag "added action #{control} to parent #{parent}"
        added control
      end

      # :nodoc: called by +add+ if the control was an animation
      def addAnimation control, quickyhash = nil, &block
        control.parent = self
        control.setup quickyhash, &block
        added control
      end

      # :nodoc: called by +add+ if the control was a state
      def addState control, quickyhash = nil, &block
        control.parent = self
        control.setup quickyhash, &block
        added control
      end

      # :nodoc: called by +add+ if the control was a model
      def addModel control, hash, &block
#         @model ||= nil
        control.setup hash, &block
#         want_data!            this is a toplevel call. There is no need to do this.
# and it wrong for comboboxes or lists that are assigned local data.
#         unless @model.equal? control
#           @model.removeObserver(self) if @model
#         tag "#{self}::addModel(#{control})"
        @model = control
#           @model.addObserver(self) if @model
#         end
        control.parent = self
        added control
      end

      # :nodoc:
      def setupQuickyhash hash
#         tag "#{self}.setupQuickyhash(#{hash.inspect})"
        hash.each do |k, v|
#           tag "#{self}.#{k}(#{v})"
          unless k == :postSetup || k == :qtparent # and other hacks!!
            # mostly if multiple args are put in a hash, they MUST become an array
            # this is inconvenient for many funcs.
            # so we ALWAYS unpack the array to the original args.
            # to really pass an array as single argument use double brackets: [[ ]]
            if Array === v
              send(k, *v)
            else
              send(k, v)
            end
          end
        end
      end

      # return macros array, creating it if it was undefined
      # Macros are executed right after the setup block (if present)
      def macros!
        @macros ||= []
      end

      # Return or set the name (a symbol, not a string).
      # If the name is set the control is registered in the containing form and
      # can be referenced by a method with the same name. This is very usefull
      # since all callbacks in the system are executed in the context of the
      # containing form.
      # *Important*: the name must not clash with a control internal or public
      # method, so make sure you use a system like prefixing controls with 'my'
      # or 'm_'.
      #
      # Example:
      #
      #         Reform::app {
      #           form {
      #             label {
      #               name :johnny
      #             }
      #             button {
      #               whenClicked { johnny.text = 'johnny' }
      #             }
      #           }
      #         }
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
          objectName && objectName.to_sym       # can be nil (STRANGE??)
        end
      end

      # note that form has an override.
      # Called if a control is given a name. It then becomes a reference singleton method
      # in the containing form.
      def registerName aName, aControl
  #       aName = aName.to_sym
  #       define_singleton_method(aName) { aControl }  not really used anyway
        containing_form.registerName(aName, aControl)
      end

      # normally you can define a callback here. But if you pass no block but a width and height
      # instead the callback is called with those arguments.
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
      # can be used for postProcessing. Example: initialization parameters are stored and
      # executed in one go.
      # the default executes any gathered macro's. Then, if a model was set it calls
      # updateModel to initialize all connecting controls.
      # So you should call this first if you override this method
      def postSetup
#         tag "#{self}#postSetup, model=#@model"
        executeMacros
        # this is a dirty trick, but if a @localmodel is set (combo/list/table/ etc)
        # then these have @model == @localmodel (initially at least)
        # and we don't want to propagate the internal model to themselves.
        # It could even be that an external model already did propagate and then we
        # are doing again.
        # So this code may very well be wrong
        if instance_variable_defined?(:@model) && !instance_variable_defined?(:@localmodel)
          STDERR.puts "warning: #{self}: start model propagation from postSetup (probably OK)" if $VERBOSE
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

      # Returns true if the control is a widget.
      # Required because some things (like scene) inherit Widget but are realy no widgets
      def widget?
      end

      #Returns true if the control is a layout  Better use Layout === x
      def layout?
      end

      # Model === x will not work, since Model is not a class. Maybe it should be now we move to Structure
      # as interface??
      def model?
      end

        # better use AbstractAction === x.
      def action?
      end

      # may return nil or a layout instantiator symbol (like :formlayout, :hbox, :vbox)
      # This answers the question: if this control is added to a form, which kind of
      # layout should we use. The default is :vbox.
      def auto_layouthint
        # labeledwidget takes formlayout, which makes sense.
        # If I pass nil back the form will add the widget as is, and the result is pretty
        # terrible.
        :vbox
      end

#         - the specific value of nil stands for a nonset value. This could be automatically
#           converted to 0 or an empty string, but the control must not treat the value as
#           valid by default and validation must be triggered if the user attempts to 'commit'
#           the formdata.
#         - controls that can be changed should be protected if the accompanying setter is
#           not available.
#         - controls can set a @connector, that overrides @name.
#         - if :initializing is set in 'options' the control must keep or set its 'clean'
#           state, and must
#           treat the field as being untouched by the user. In particular no triggers should be
#           applied, and no validation should take place.
#         - controls that have components must propagate the connection, even if they have no
#           name.
#         - if the value of a control does not change by the connect operation, no triggers must
#           be called (at least not now).
      def updateModel aModel, propagation
        if propagation.debug_track?
          STDERR.print "#{self}::updateModel(#{aModel}, #{propagation.inspect}), connector=#{connector}\n"
        end
#         raise 'WTF' unless Model === aModel
        do_callback = instance_variable_defined?(:@whenConnected)
        if cid = connector
          # really important, if nothing changes for us, so also not for our children.
          unless check_propagation_change(propagation, cid)
            STDERR.print "#{self}::updMod, check_propagation_change FAILS\n" if propagation.debug_track?
            return
          end
          do_apply = propagation.sender != self
#           tag "#{self}::updateModel, do_apply = #{do_apply}, sender = #{propagation.sender}, cid = #{cid} change = #{propagation.get_change(cid)}"
          unless do_apply || children || do_callback
            if propagation.debug_track?
              STDERR.print "#{self}::updMod, I am sender, and have no children, and do_callback is not set\n"
            end
            return
          end
          if aModel.respond_to?(:model?) && aModel.model?
            data = aModel.apply_getter(cid)
          elsif Proc === cid
            data = cid.call(aModel)
          else
            data = aModel
          end
          # for simple fields the connected model is the container.
          # For example Edit.model is set to the record, same for Combo etc.
          # But if the result of cid is in fact a model, then we use that as that is the thing we gonna need.
          # This happens for frames and forms.
#           tag "applied cid #{cid.inspect} on model #{aModel}-> #{data.inspect}"
#             tag "data.value = #{data.respond_to?(:value) && data.value.inspect}"
          @model = if (is_model = data.respond_to?(:model?) && data.model?) then data else aModel end
#             tag "applied #{cid} on #@model -> #{data.inspect}, calling #{self}::applyModel"
          applyModel data if do_apply # , aModel the callee can use @model
#           tag "is_model = #{is_model}"
#           unless is_model && (children || do_callback)  # VERY INCONVENIENT. Why can't I pass a string
      # directly to an edit contained somewhere?
          unless children || do_callback
            if propagation.debug_track?
#               if is_model
                STDERR.print "#{self}::updMod, applied model, but no propagation, since I have no children " +
                             "or do_callback is not set\n"
#               else
#                 STDERR.print "#{self}::updMod, applied model, but no propagation, since data is not a Model\n"
#               end
            end
            return
          end
        else
          data = aModel
        end
        # if there is no cid (common case) we must propagate to all children
        propagation = propagation.apply_getter(cid) if cid
        # end it is 'data' that is now propagated, and not 'aModel'! We must use the cid.
        propagateModel data, propagation if children
        rfCallBlockBack(data, propagation, &@whenConnected) if do_callback
      end

      # return the model of the containing frame or form, traveling upwards until one is found.
#       def effectiveModel
#         parent.effectiveModel
#       end

      # true if model is set on this control. Can only be true for forms or frames
#       def effectiveModel?
#       end

      # returns the enclosing frame (or itself, if it is a frame)
      def frame_ex
        if Frame === self then self else parent.frame_ex end
      end

      # as a replacement for findChildren. Note that klass is a Reform class!
      # it works recursively.
      # However, it also enumerates itself, if the condition applies.
      # Works as iterator, the controls located are passed to the block
      def find klass = nil, name = nil, &block
        return to_enum(:find, klass, name) unless block
        if (!klass || klass === self) && (!name || name === @qtc.name)
#           tag "find, klass=#{klass}, #{self} is a #{klass}, req. name = #{name}. Calling block!"
          block[self]
        end
        chlds = children and chlds.each { |child| Control === child and child.find(klass, name, &block) }
      end

      alias :findChildren :find

      # can be used as a bool too. For comboboxes and tables this may be set, while effectiveModel is nil.
#       def model
#         instance_variable_defined?(:@model) ? @model : nil
#       end

      def geometry=(*value)
        @qtc.geometry = *value
      end

      # connected model or nil
      attr :model

      # note we already have the reader above somewhere, Even with attr_writer it is legal
      # to pass an array like 'connector :key1, :key2'.
      # These keys are then applied in that order.
      attr_writer :connector

      # the owner form.
      attr :containing_form

      alias :containingForm :containing_form

      # same as containingForm
      def dynamicParent
        parent.dynamicParent
      end

      # override
      def deleteLater
        # it seems Qt::Object deleteLater is not always available. ??
        if @qtc
          if @qtc.respond_to?(:deleteLater)
            @qtc.parent = nil
            @qtc.deleteLater
            @qtc = nil
          else # guess it is a GraphicsItem (not a Qt::Object!)
            @qtc.parentItem = nil
            #@qtc.dispose               SEGV
          end
        end
        self.parent = nil
        super
      end

      def define quickyhash = nil, &block
        DefinitionsBlock.new(containing_form).setup(quickyhash, &block)
      end

      # Qt control that is wrapped
      attr :qtc

      # an Array of macros,   we may need a separate index for named macros but
      # I forgot what needed that. Probably broken now.
      attr :macros

#       # BROKEN in qtruby!!! (destroys encoding)
#       def tr text
#         encoding = text.encoding
#         tag "encoding = #{encoding}"
#         super.encode(encoding)
#         super
#       end
  end # class Control

end # Reform