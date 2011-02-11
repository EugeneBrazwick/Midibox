
# Copyright (c) 2010 Eugene Brazwick

# require 'continuation'
require 'Qt'
require 'reform/control'

module Reform

  class ProtocolError < ReformError
  end

#   the Propagation class is used when data is emitted from a datasource, due to a change,
#   or initialization.
#
#   Receivers of the data can inspect it to see if they can do anything usefull with it.
#
#   The Control class dispatches the notification through two methods
#     update_model, and propagate.
#   Update model informs a control, and propagate informs its children.
#   The sender of a notification never receives the notification itself.
#   Only controls that 'want_data?' will receive the update_model and propagate
#   methods.
#   If a control has another model (external, so not the data within a combobox)
#   set, then it will never receive propagations from outside its tree.
#
#   Only Frame can have a model set. A widget can have two frames with completely independend
#   models.
#
#   I noticed a quirck in the design.  Depending attributes of a model don't get their 'changed'
#  flag set if the data they depend on changes.  For example, in TimeModel, if the +current+
#  value changes then +to_s+ and +toString+ must also be changed.
#  To mend this you can call for example:
#
#           dependencies_changed :to_s, :toString
#
# But this is TOO TRICKY!!!
#
# It is simple if a control can say   'connector: :f'
# But how does a form connect to some selected row in an array?
# This can only be done if the connector is set to '4' or whatever the selected row is by the
# caller.
# It depends on how complicated we design stuff. Suppose we have a form showing a table with rows.
# We doubleclick or Enter on a row to open a form where all fields are shown in plain edits
# (if the table does not show all fields). If the active row then changes, should our opened
# form reflect this? I would say no.
# Is it possible to open many instances of the same form. I would say yes.
# So an opened form is given a specific connector and that may change later, but only for
# StructuralChanges (internal fixup). Example: you press the 'sort' button in the table.
# So row 4 is now suddenly row nr 1. Our opened forms should be notified and respond internally
# but no visible change is required.
# Then the user undoes the sort. Same story.
#
# Note that hashes do not have this problem at all, provided forms use the hash index.
# But even then a form cannot set the connector in advance. We need some specific symbols
# to deal with this?
#
# But even for hashes using StructuralChange is important! The reason is that Qt views must
# be notified too.
#
# The following line in Control is important;
#       propagation = propagation.apply_getter(cid) if cid
# when propagating changes the current keypath changes too. So we know where we are in the model.
#
# A control no longer has a simple 'value' when receiving a propagation as complicated
# transactions may involve several changes for their path (cid).
# For example, a TableView can receive a change of an insert where we have
#   - to add a row ie, to make the room for it, shifting rows down if necessary
#   - to actually update the values in the inserted row.
  class Propagation
      Initialize = true
      NoInit = false
    private
      # Parameters:
      # [sender] original instance that started the transaction
      # [keypaths] index of changed attribs, the index of the stack of propertychanges. Example:
      #                 s[4][:x] = 4
      #              would add [4, :x] => PropertyChange(s, 4, :x, s[4][:x]) to the index
      #
      #                 s[:x][4, 4] = 1, 2, 3, 4
      #              would add [:x] => PropertyChange(s, :x, s[:x].clone)  to the index
      #              we can only change simple indices like a fixnum or a hashsymbol.
      # [init] if true this is considered a new structure completely
      def initialize sender, keypaths = nil, init = false, current_path = nil
        @sender, @keypaths, @init = sender, keypaths, init
        @init = true if !@keypaths || @keypaths[[]] # the root changed.
        @current_path = current_path
#         tag "Propagation.new SENDER ====  #{sender}, caller =#{caller.join("\n")}!!!!!!!!!!!!!!!!!!!"
        @debug_track = false
      end

    public
      attr :sender, :keypaths

      attr_writer :debug_track

      def debug_track?
        @debug_track
      end

# Suppose I listen to keypath  [:x, 4], this means my cid is 4 (NO!)
# any [:x, 3] is in de keypaths hash.
# This means that my parent must have cid :x (NO!). And this would set current_path to [:x]
#
# But now only :x has changed.
# then [:x, 4] is not in the keypath.
# This implies we must check all prefixes...
#
# DANGEROUS THOUGHTS:   my cid can be [:x, 4] to begin with!
#
# Alternative:
#
# Changes the keypaths themselves in 'apply_getter'
# any keypath lacking the connector as first entry can be dropped out.
# all the others do a 'shift'
# Checking the cid in changed? means it is present as a first entry.
# No that is even worse.
      def get_change connector
        return true if @init || Proc === connector
        ch = @keypaths[[]] and return ch                # shortcut same as 'init'
        path =  case connector
                when Array
                  if connector[0] == :root
                    connector[1..-1]
                  elsif connector[-1] == :self
                    connector[0...-1]
                  else
                    connector
                  end
                when :self then []
                else [connector]
                end
        path = @current_path + path if @current_path
#           tag "get_change, @keypaths = #{@keypaths.keys.inspect}, current_path = #{@current_path.inspect}"
        subpath = []
        path.each do |cid|
          return true if Proc === cid
          subpath << cid
          ch = @keypaths[subpath] and return ch
        end
        nil
      end

      # true if the whole model should be considered changed...
      def init?
        @init
      end

      # for debugging
      def changed_keys
        @keypaths && @keypaths.keys
      end

      # returns a new Propagation with one link (connector) added to the active/current path.
      # Used by Frame to pass on a model to its children
      def apply_getter connector
        return self if @init || Proc === connector   # it does not matter
        Propagation.new(@sender, @keypaths, @init, (@current_path || []) + [connector])
      end
  end # class Propagation

=begin
Models support Transactions.
All changes made to a model within a transaction can be rolled back to their
original value. And notification of change is delayed until the transaction is
committed.
Due to the immense complexity in allowing transaction on any ruby object this is
currently far away from  a proper reliable system.
This class should not be used directly. Instead use Model#transaction <block>
to setup a transactional scope.

In the future transactions can be nested. Propagation is disabled within a nesting
transaction, even if it is committed.
In short, other controls can not 'dirty read'.

Currently only 1 transaction can be active at any time.
If no transactions scope is created any change to the model will use a implied
transaction that is immediately committed (and at that point propagation starts).
=end
  class Transaction #  < Qt::UndoStack CHAOS???

  # unique global instance
      @@transaction = nil

      # this class is send as an 'event'. However propertychanges within a transaction
      # are stored together.
      # On commit of the transaction the whole change is pushed to all controls listening.
      # But changes can be rather complicated if inserts and deletes are also involved
      # If a key is involved here we would like to send an extra message, where the
      # structural change itself is stored.
      # Example:
      #        array_x[3, 1] = nil
      # This causes the property at key [:array_x, 3] to be deleted. So it sends a PropertySpliced
      # event, with that keypath.
      # However the array itself is also affected. So we must send a StructureSpliced event as well.
      # StructureChanges have no 'oldvalues', but they must keep 'undo' information.
      # In fact the PropertySpliced event no longer needs to undo anything, as the property itself
      # never changed.  Conclusion: it can go?
      # No. The actual data involved will be stored there. Structure changes do NOTHING with contents.
      # Example: a form keeping track of a deleted record will show blanks. Or perhaps it will close?
      class AbstractModelChange
          # hack, this represent a reasonable safe 'NoValue' value
          class NoValue
          end

        private # AbstractModelChange methods

          # I believe that model is always the root-model of the system
          # but it seems convenient to support more than one model in an application
          def initialize model, keypath
            @model, @keypath = model, keypath
            raise "BOGO path, caller = #{caller.join("\n")}" if keypath == [nil]
            @model or raise 'TOTAL CORRUPTION'
          end

          # apply the keypath to the model, returning the value
          # See Model#apply_getter
          def locate
            @keypath ? @model.apply_getter(@keypath) : @model
          end

          # locates the parent keypath in the model and returns the result of applying it.
          # See Model#apply_getter
          def locate_parent
            @keypath && @keypath.length > 1 ?  @model.apply_getter(@keypath[0...-1]) : @model
          end

        public
          attr :model, :keypath

          # returns true if change inserted something
          def inserted?
          end

          # returns true if change deleted something
          def deleted?
          end
      end

      # class for changes of a structure. Be it a hash, array or object.
      # Structural changes of hashes or objects are not really problematic though.
      # We are not interested in actual data, but only how the structure is changed internally.
      # We must be able to undo the change as well. In case of deletes, this means that new
      # records are added using nils.
      class StructuralChange < AbstractModelChange
      end

=begin
  this seems easy enough?

  Normally you delete an entire item from an array. So the undo must
  have the oldvalue ready!

  But we violate the idea that structural changes should carry no data...
  TODO: this is already a mess
=end
      class PropertyDeleted < StructuralChange
        private
          def initialize model, keypath, oldval
            super model, keypath
            @oldval = oldval
          end

        public # PropertyDeleted methods
          def undo
#             tag "#{self}::UNDO, locate[#{@keypath[-1]}] := #{@oldval.inspect}"
            locate_parent.value[@keypath[-1]] = NoValue
          end

          def deleted?
            true
          end

      end

# IMPORTANT we use a shortcut: locate.value iso just locate
# This is rather illegal as it assumes that the chosen operation is still valid on the wrapped element
# Normally this would be the case. But.....

      # only for arrays.  x = [1,2,3,4]                         x = [1,2,3,4]
      #                   x.delete_at(2) -> 1,2,4               x.delete_at(-2) -> 1,2,4
      #                   x.insert(2, 3) -> 1,2,3,4             x.insert(-2, 3) -> 1,2,3,4
      class PropertySpliced < PropertyDeleted
        private
          def initialize model, keypath, oldvals
            super model, keypath, oldvals
            raise 'oldvals must be array' unless Array === oldvals
          end

          def undo
#             tag "#{self}::UNDO, locate (#{locate.value.inspect})[#{@keypath[-1]}, 1] := #{@oldval.inspect}"
            locate_parent.value.insert(@keypath[-1], *@oldval)
          end
      end

      # NOTE: an abort on a nonexisting value will make that value become nil instead.
      # It is a bootload of work to really test for additions.
      # Also if we have x == [1, nil] and x == [1] then in both cases x[1] == nil.
      # the correct query would be idx < length, for arrays
      # for hashes it is has_key?(idx)
      class PropertyAdded < StructuralChange
        private
          def initialize model, keypath, count = 1
            super model, keypath
            @count = count
          end

        public # PropertyAdded methods
          def undo
            locate_parent.value.slice!(@keypath[-1], @count)
          end

          def inserted?
            true
          end
      end

      # use this when an anonymous entry is pushed on the array. The keypath is 1 shorter.
      class PropertyPushed < PropertyAdded
        private
          def initialize model, keypath, count = 1
            super
          end
        public
          def undo
            locate.pop(@count)
          end
      end

      class PropertyShifted < PropertySpliced
          def undo # similar to Pop
            locate.value.unshift(*@oldval)
          end
      end

      class PropertyUnshifted < PropertyPushed
          def undo
            locate.shift(@count)
          end
      end

      class PropertyPopped < PropertySpliced
        public
          def undo
            locate.value.push(*@oldval)
          end
      end

      # class for changes that actually involve data.
      # This can still be an insert (new data) or delete (possible to undo, so olddata is required)
      # But we are not really interested WHERE something is deleted or inserted.
      class PropertyChange < AbstractModelChange

        private
          def initialize model, keypath, oldval = nil
            super model, keypath
#             tag "New #{self} (#{model}, #{keypath.inspect}, #{oldval})"
            @oldval = oldval
          end

        public

          def undo
#             tag "#{self}::UNDO, kp= #{@keypath.inspect}, @model[....][#{@keypath[-1]}] := #@oldval #######################################"
            locate_parent.apply_setter @keypath[-1] || :self, @oldval
          end

          attr :oldval

          # as in 'from value X to value Y'
          def updated?
            true
          end

      end # class PropertyChange

    private # Transaction methods

      def initialize model, sender = nil
        @stack = []
#         tag "tran test"
        raise ProtocolError, 'Protocol error, transaction already started' if @@transaction
        raise "total chaos, caller=#{caller.join("\n")}" unless model
#         tag "BEGIN WORK, SENDER IS NOW #{sender}, caller=#{caller.join("\n")}"
        @tranmodel, @sender, @@transaction = model, sender, self
        @root = @tranmodel.root
        @keypaths = {}
        @committed = @aborted = false
        @debug_track = sender && sender.track_propagation # assuming sender is a Control
#         tag "debug_track = #@debug_track, sender = #{sender}"
        if block_given?
          begin
            begin
  #             tag "CALLING BLOCK with self #{self}"
              self == @@transaction or raise 'WTF???'
              yield self
            rescue Exception=>e
              if @@transaction
#                 tag "FAILED TO EXECUTE tranblock(#{e}, #{e.backtrace.join("\n")}), tran is now #{@@transaction}, abort"
                abort
              end
              raise
            end
          ensure
            if @@transaction
#               tag "EXECUTED tranblock, tran is now #{@@transaction}, commit unless nil"
              commit
              # bail out if the propagate fails...
            end
          end
        end
      end

    public # Transaction methods

      attr :root # this is the root!!!
      attr :tranmodel
      attr :sender # for debugging

      def debug_track!
        @debug_track = true
      end

      def changed_keys
        @keypaths.keys
      end

      # call this to add more complex changes to the undostack
      def push propch
#         tag "Transaction#push(#{propch.inspect})"
        raise ProtocolError, 'Protocol error, no transaction' unless @@transaction
        kp = propch.keypath
        kp = @tranmodel.keypath + kp unless @tranmodel.keypath.empty?
        if kp && StructuralChange === propch
          @keypaths[kp[0...-1]] = propch
        else
          @keypaths[kp] = propch
        end
        @stack.push propch
        # set last_property so addDependencyChange can work with that.
        @last_property = propch
      end

      def self.transaction
#         tag "self.transaction, t = #{@@transaction}"
        @@transaction
      end

      def commit
#         tag "#{self}.COMMIT WORK, @@tran= #{@@transaction}, aborted=#@aborted, sender = #@sender"
        # NOTE: tr() only works on Qt::Object...
        raise ProtocolError, 'Protocol error, no transaction to commit' unless @@transaction
        raise ProtocolError, 'Protocol error, transaction inactive' if @aborted || @committed
        if @debug_track
          STDERR.print "create Propagation, sender = #@sender, model=#{root}, root=#{@tranmodel.root}, parent=#{@tranmodel.parent}\n"
        end
        propch = Propagation.new(@sender, @keypaths)
        propch.debug_track = true if @debug_track
        root.propagateChange propch
#       rescue
#         abort         CANNOT BE DONE. After propagation the other parts of the system are already altered
# abort does nothing about that.
      ensure
        # free memory and blocks further operations
        @stack = @keypaths = nil
        @@transaction = nil
        @committed = true
#         tag "COMMIT WORK OK"
      end

      def abort
#         tag "#{self}.ABORT WORK, aborted := true, globtran=#{@@transaction}, stack=#{caller.join("\n")}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        raise ProtocolError, 'Protocol error, no transaction to abort' unless @@transaction
        raise ProtocolError, 'Protocol error, transaction already aborted' if @aborted
        raise ProtocolError, 'Protocol error, transaction already committed' if @committed
        @aborted = true
        # FIRST destroy the undo's since they will call apply_setter
        @stack.pop.undo until @stack.empty?
      ensure
        @@transaction = @stack = @keypaths = nil
      end

      alias :rollback :abort

      def aborted?
        @aborted
      end

      def committed?
        @committed
      end

      def active?
        !@aborted && !@commited
      end

      # common case, for updates of single keypaths.
      # The keypath should be the *local* keypath, not the path starting at _root_
      def addPropertyChange *keypath, oldval
#         tag "self = #{self}, @@transaction = #{@@transaction}, oldval=#{oldval}"
        keypath = keypath[0] if Array === keypath[0]
        push(PropertyChange.new(@tranmodel, keypath, oldval))
      end

      # call this method to add pseudo changes. See TimeModel source for an example.
      # Adds the @last_property changed (as set by +push+)
      def addDependencyChange *keypath
        keypath = keypath[0] if Array === keypath[0]
        @keypaths[@tranmodel.keypath + keypath] = @last_property
      end
  end # class Transaction

=begin


The model module is designed to supply an interface for datasources.
It should cooperate well with Qt's models (DOES NOT).
It supports transactions.
It supports enhanced notifications of changes.

And this datapassing is used instead of Qt's event system.
In general events are boring, and data is interesting.

Each Control can say it wants notification by supplying a 'connector', or by creating
a connector in a special Control, the DynamicAttribute, which sole purpose is the
delivery of a notification.

To not overload the objecttree we only pass data to controls that have a descendant
with a connector.

The old rule that 'names' imply 'connectors' is dropped completely.


=end

  module Model

      module ClassMethods
        private
=begin rdoc
  macro to assign the 'dynamic_writer' property to an attribute.
  This is the same as attr_writer, but dynamicPropertyChanged will be called automatically.
  This way of calling it is preferred.
#   What goes wrong?
  You should make sure that assigning is the only way your property changes.
  This seems easy, but...

      newval = myproperty
      newval[2,1] = '!'
      myproperty = newval

  This goes terribly wrong!
  The third assignment changes nothing since newval.equal?(myproperty).
  It is simply the same object. As a result dynamicPropertyChanged is NOT called, since
  the property did not change, as far as dynamic_writer is concerned.
  Solution:
      newval = myprop.dup
      newval.mutilate
      myprop = newval

  will work as expected.

  This is the same within Qt.
  If you say
    color = pen.color
    color.mutilate
  the pens color will not be changed. You must set it again
  using
    pen.color = color
  even more, the pen must also be set in the item again!
    item.pen = pen
=end
          def dynamic_writer attrsym
#             tag "WHAT??"
            methname = (attrsym.to_s + '=').to_sym
            define_method methname do |value, sender = nil|
#               tag " I AM HERE"
              # the question is: who called this method??
#               Binding.of_caller do |binding|          WORKS ONES ONLY .....
#                 sender = eval 'self', binding
                #               tag "HERE Sender = #{sender}"
              attr = ('@' + attrsym.to_s).to_sym
              prev = instance_variable_defined?(attr) ? instance_variable_get(attr) : nil
#               tag "#{attr} := #{value}, prev = #{prev}"
              return if prev == value
              pickup_tran(sender) do |tran|
                # Existing tran. Note it may be a tran aborting, and resetting our data
                # in that case, do not change anything.
                tran.addPropertyChange(attrsym, prev) unless tran.aborted?
                instance_variable_set(attr, value)
              end
            end # dynamic methname
          end

          def dynamic_accessor *attrsyms
            # DO NOT USE 'for' here
            attrsyms.each do |attrsym|
              define_method attrsym do
    #             tag "#{self}.#{attrsym}()"
                attr = ('@' + attrsym.to_s).to_sym
    #             tag "calling instance_variable_get(#{attr})"
                instance_variable_defined?(attr) && instance_variable_get(attr)
              end
      #         public attrsym  EVIL
              dynamic_writer attrsym
            end
          end

          def dynamic_bool *attrsyms
            attrsyms.each do |attrsym|
              define_method "#{attrsym}?".to_sym do
                attr = ('@' + attrsym.to_s).to_sym
                instance_variable_defined?(attr) && instance_variable_get(attr)
              end
              dynamic_writer attrsym
            end
          end

          class << self
            alias :dynamic :attr_reader
            alias :dynamic_reader :attr_reader
          end

        public

          def parent_qtc(*)
          end

      end # ClassMethods

    private      # Model methods

    # override
      def self.included mod
  #       tag "Included by #{mod}"
        mod.extend ClassMethods
      end

      # this saves a lot of duplication. The block is passed the transaction.
      def pickup_tran sender = nil
        if tran = Transaction.transaction
          yield(tran)
        else
          Transaction.new(self, sender) do |tr|
            return yield(tr)
          end
        end
      end

#       @@root = nil

#       def initModel
#         @@root ||= self
#       end

#       def self.root
# #         @@root
#       end

    public # Model methods

      def root
        @root or raise "MAYHEM, modelconstructor #{self} did not set @root!!!"
      end

      attr_writer :root

      def propagateChange propagation
#         (@observers ||= nil) and @observers.each do |o|
#         tag "propagateChange"
        if parent
          parent.updateModel self, propagation
        else
          STDERR.puts "Warning: propagateChange is ignored if your model (#{self}) has no parent!!" if $VERBOSE
        end
#         end
      end

      # set or get the name of the model
      def name aName = nil
        return instance_variable_defined?(:@name) && @name if aName.nil?
  #       tag "registerName in #{containing_form}"
        @name = aName
        containing_form.registerName aName, self
      end

      attr_accessor :containing_form

      # Control compatibility
      def postSetup
      end

      # Control compatibility
      def widget?
      end

      # observers are always ReForms, currently
# #       def addObserver observer
#         (@observers ||= []) << observer
#       end

#       def removeObserver observer
#         @observers.delete observer
#       end

#       returns whether +name+ may function as 'getter' on the model
#       names like 'getX' are currently not supported.
#       However, a proc can very well be a getter, where the object is
#       passed as an argument.  This makes it possible to code the
#       text or value to use in the gui, and not in the model.
#       Because of this any Proc passed will return true.
      def getter? name
        return true if name == :self || Proc === name
  #       tag "Does #{self.class}##{name} is a public method?"
        m = (public_method(name) rescue nil) or return
  #       tag "m.arity = #{m.arity}"
        -1 <= m.arity && m.arity <= 0
      end

      # To apply the getter, this method must be used.
      # +name+ should be a hashindex (pref. a Symbol), or an arrayindex (Fixnum)
      # The name +:self+ is special (more or less). 'self' is not a method in a ruby but you
      # could consider it to be one.
      def apply_getter name
#         tag "#{self}::apply_getter(#{name.inspect})"
        case name
        when :self then self
        when :root then root
        when Proc then name.call(self)
        when Array
          name.inject(self) do |memo, nam|
#             tag "memo = #{memo}, component = #{nam.inspect}"
            memo && memo.apply_getter(nam) # ).tap{ |t| tag "Result of application = #{t.inspect}"}
          end
        else
          return nil unless (m = public_method(name)) && -1 <= m.arity && m.arity <= 0
  #       tag "apply_getter #{name} to self == 'send'"
  #       if respond_to?(name)
          send name
        end
      end

  #     def method_missing symbol, *args, &block
  #       send name, *args, &block
  #     end

      def apply_setter name, value, sender = nil, more_args = nil
        case name
        when :self
#           tag "apply_setter"
          # as an unwanted feature it will call 'postSetup' on self!!!!! FIXME(?)
          # setting the model will change the observers
          # FIXME: this is WRONG!  we may be within a transaction.
#           Array.new(@observers || []).each do |o|
#             raise 'DEPRECATED: observers'
  #           tag "Resetting model #{self} to observer #{o}"
          parent.updateModel value, Propagation.new(sender, nil, true)
#           end
        when Proc
          # ignore. Notice that setter? already returns false, but some bogo controls call this anyway
        when Array
          sub = name[0...-1].inject(self) { |v, nm| v && v.apply_getter(nm) } and
            sub.apply_setter(name[-1], value, sender)
        else
          name = name.to_s
          name = name[0...-1] if name[-1] == '?'
          pickup_tran(sender) do |tran|       # this is only used to get the sender in
            tran.debug_track! if more_args && more_args[:debug_track]
            send(name + '=', value)#  , sender)
          end
        end
      end

=begin rdoc
      returns whether name may function as 'setter' on the model, if
      suffixed with an '=' char.
      names like 'setX' are currently not supported
=end
      def setter?(name)
        case name
        when :self then true
        when Proc then false
        else
          n = name.to_s
          n = n[0...-1] if n[-1] == '?'
          m = (public_method(n + '=') rescue nil) or return false
          -2 <= m.arity && m.arity <= 1
        end
      end

      # key -> any. When a model consists of an array, hash or list of other objects
      # and if to be used as a datasource in things like combobox, we must have a
      # key for each instance. If you use BasicObject somehow, this should be overriden.
      # If your keys are visible, an override would be convenient as well.
      def key
        __id__
  #       raise ReformError, tr("to be usefull, #{self.class} should have an override for 'key'")
      end

      def setupQuickyhash hash
        raise "ARGHHH, caller = #{caller.join("\n")}" unless Hash === hash
        hash.each do |k, v|
  #         tag "send(#{k.inspect}, #{v.class} #{v})"
          send(k, v) unless k == :postSetup || k == :qtparent
        end
      end

      def addTo parent, hash, &block
#         tag "#{self}::addTo"
        parent.addModel self, hash, &block
      end

      def model?
        true
      end

      def keypath
        instance_variable_defined?(:@keypath) ? (@keypath || []) : []
      end

      # the transaction is passed to this block
      # transaction do |tran| .... end   runs the block in a transaction, if it fails halfway
      # the original state of @root is restored (more or less)
      # without args it returns the current transaction
      def transaction(sender = nil, &block)
        return Transaction.transaction unless block
#         tag "Sender = #{sender}" # ie, the creator of the transaction
        Transaction.new(self, sender, &block)
      end

      # usefull for array like models. If only a single row is present, just return 1
      def length
        # TO AVOID CONFUSION:!!!
        raise "#{self.class}#length is not implemented, caller=#{caller.join("\n")}"
      end

      def empty?
        length == 0
      end

      # grab a row, can return a Model or simple data like Numeric, String etc.
      # It should never return an Array or Hash or a complex instance that is not Model.
      def row(numeric_idx)
        raise "#{self.class}#row is not implemented"
      end

      # iterate the rows
      def each
        return to_enum unless block_given?
        (0...length).each { |row| yield(self[row]) }
      end

      # to override in implementors! Note that idx need not be numeric.
      # Array like models can use this default.
      def [](idx)
        row(idx)
#         raise "#{self.class}#[] is not implemented"
      end

      # helper method to handle qtruby kludges
      def self.enum2i k
        k.is_a?(Qt::Enum) ? k.to_i : k
      end

      # try to retrieve key from value by looking to a field called 'id'
      # Unfortunately sometimes the value is not a model but a raw hash.
      def value2key value, view # or widget
        # note that Strings have to_i as well.
        case value
        when Fixnum, Qt::Enum then value.to_i
        else
          idid = view.key_connector || :id
          if value.respond_to?(idid)
            value.send(idid)
          elsif Hash === value
            # just respond_to(:[]) will not work properly as x[:dd] is illegal for arrays
            value[idid]
          else
            nil
          end
        end
      end

      # Hm,... there are more classes that use these very basic methods.

      # this is dangerous but makes models work properly as 'controls'
      # since otherwise I get severe yaml load errors (SEGV's etc)
      # It seems Qt::Object does not yaml very well.
      def parent_qtc_to_use_for reform_class
        #reform_class.respond_to?(:parent_qtc) &&
        reform_class.parent_qtc(self, effective_qwidget)
      end

      # Same here, duplicating Control API
      def add child, quickyhash, &block
        child.addTo(self, quickyhash, &block)
      end

      def setup hash = nil, &initblock
        instance_eval(&initblock) if initblock
        setupQuickyhash(hash) if hash
        postSetup
        self
      end

      attr_writer :keypath
      attr_accessor :parent
      attr :qtc

      def clean?
        !@dirty
      end

      def dirty?
        @dirty
      end

      def clean!
        @dirty = false
      end

      def dirty!
        @dirty = true
      end

      def draggable?
      end

      # sends a propertyChanged event for each field mentioned
      def touch sender, *fields
        transaction(sender) do |tran|
          fields.each do |field|
            tran.addPropertyChange field, apply_getter(field)
          end
        end
      end

      # the model should override this to something more distinguishable
      def mimeType
        'text/plain'
      end

      def mimeData records
        res = Qt::MimeData.new
        itemData = Qt::ByteArray.new
        dataStream = Qt::DataStream.new(itemData, Qt::IODevice::WriteOnly)
#         tag "store yaml #{text} in stream"
        records.each do |rec|
#           tag "packing record #{rec.inspect}"
          dataStream << rec.to_yaml
        end
        res.setData mimeType, itemData
        res
      end
  end # module Model

  # This class implements Model but is also a Control.
  # There are however problems between YAML and Qt::Objects.
  # Better avoid this if saving and loading of the model is required.
  class AbstractModel < Control
    include Model
    private
      def initialize parent = nil, qtc = nil
        super
        @root =
        if parent && parent.respond_to?(:model?) && parent.model?
          @root = parent.root
#           tag "Parent (#{parent}).root = #{parent && parent.root}"
          raise 'WTF' unless @root
        else
          @root = self
        end
      end

#     def length  # not likely
#       @qtc.rowCount           # and rowCount requires an index too...
#     end

      # Model already has this but something strange is going on!!
#       def addTo parent, hash, &block
#         parent.addModel self, hash, &block
#       end
  end

end # module Reform

if __FILE__ == $0
  require 'reform/app'  # for tag method
  include Reform

  class SimpleStruct
    include Model
    def initialize
      @field = 24
    end

    def propagateChange prop
      tag "propagate: field: #@field, #{prop.inspect}"
    end

    dynamic_accessor :field

  end

  def test
=begin
    s = SimpleStruct.new
    s.field = 45
    s.transaction(self) do
      s.field = 24
      tag "AND now expect prop:"
    end
=end
 #=begin
    s = SimpleStruct.new
    s.transaction(self) do |tran|
      raise 'WTF' unless tran == Transaction::transaction
      s.field = 82324
      raise 'WTF' unless tran == Transaction::transaction && tran.active?
      tag "AND now expect no prop, calling ABORT!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
      tran.abort
      raise "WTF, tran=#{tran.inspect}" unless Transaction::transaction == nil && tran.aborted?
      tag "s.field #{s.field} should be restored to 24"
      raise 'WTF' unless s.field == 24
    end
 #=end
  end

  test

end # test case