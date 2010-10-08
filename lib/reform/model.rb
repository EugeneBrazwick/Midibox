
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
  class Propagation
    private
      # Parameters:
      # [sender] original instance that started the transaction
      # [attr_index] index of changed attribs, the index of the stack of propertychanges. Example:
      #                 s[4][:x] = 4
      #              would add [4, :x] => PropertyChange(s, 4, :x, s[4][:x]) to the index
      #
      #                 s[:x][4, 4] = 1, 2, 3, 4
      #              would add [:x] => PropertyChange(s, :x, s[:x].clone)  to the index
      #              we can only change simple indices like a fixnum or a hashsymbol.
      # [init] if true this is considered a new structure completely
      def initialize sender, attr_index, init = false, current_path = nil
        @sender, @attr_index, @init = sender, attr_index, init
        # current_path could be nil or [4] or [4, :x]  etc. As connectors are applied to propagation copies
        # it changes.
        @current_path = current_path
      end

    public
      attr :sender, :attr_index
#       attr_accessor :current_path

      def changed? connector
        return true if @init || Proc === connector
        path = @current_path ? [connector] : @current_path + [connector]
        @attr_index[path]
      end

      def init?
        @init
      end

      # returns a new Propagation with one link (connector) added to the active/current path.
      # Used by Frame to pass on a model to its children
      def apply_getter connector
        Propagation.new(@sender, @attr_index, @init, (@current_path || []) + [connector])
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

#       class PropertyIndex
#         private
#           def initialize *index
#             @index = index
#           end
#       end

    # After 11 clears of the Qt undostack the whole thing crashes.
      class PropertyChange #< Qt::UndoCommand #UNSTABLE

        # hack, this represent a reasonanle safe 'NoValue' value
        class NoValue
        end

        private
          def initialize root, keypath, oldval = nil
  #           super()
#             tag "New #{self} (#{model}, #{index.inspect}, #{oldval})"
            # note this clone may tragically fail for many Qt classes....
            @root, @keypath, @oldval = root, keypath, oldval
          end

          def locate
            @keypath[0...-1].inject(@root, &:apply_getter)
          end

          # certain operations have no attribute
          def locate_full
            return @root unless @keypath
            @keypath.inject(@root, &:apply_getter)
          end

        public
          def undo
#             tag "#{self}::UNDO, kp= #{@keypath.inspect}, @model[....][#{@keypath[-1]}] := #@oldval #######################################"
            locate.apply_setter @keypath[-1] || :self, @oldval
          end

          attr :oldval, :root, :keypath
      end # class PropertyChange


# IMPORTANT we use a shortcut: locate.value iso just locate
# This is rather illegal as it assumes that the chosen operation is still valid on the wrapped element
# Normally this would be the case. But.....

      # only for hashes
      # this seems easy enough
      class PropertyDeleted < PropertyChange
          def undo
#             tag "#{self}::UNDO, locate[#{@keypath[-1]}] := #{@oldval.inspect}"
            locate.value[@keypath[-1]] = @oldval
          end
      end

      # only for arrays.  x = [1,2,3,4]                         x = [1,2,3,4]
      #                   x.delete_at(2) -> 1,2,4               x.delete_at(-2) -> 1,2,4
      #                   x.insert(2, 3) -> 1,2,3,4             x.insert(-2, 3) -> 1,2,3,4
      class PropertySpliced < PropertyDeleted
          def undo
#             tag "#{self}::UNDO, locate (#{locate.value.inspect})[#{@keypath[-1]}, 1] := #{@oldval.inspect}"
            locate.value.insert(@keypath[-1], @oldval)
          end
      end

      # NOTE: an abort on a nonexisting value will make that value become nil instead.
      # It is a bootload of work to really test for additions.
      # Also if we have x == [1, nil] and x == [1] then in both cases x[1] == nil.
      # the correct query would be idx < length, for arrays
      # for hashes it is has_key?(idx)
      class PropertyAdded < PropertyChange
        private
          def initialize model, keypath, count = 1
            super(model, keypath, NoValue)
            @count = count
          end
        public
          def undo
            locate.value.slice!(@keypath[-1], @count)
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
            locate_full.pop(@count)
          end
      end

      class PropertyShifted < PropertyDeleted
#         private
#           def initialize model, keypath, oldvalues
#             super(model, keypath)
#             @count = count
#           end
#         public
          def undo # similar to Pop
            locate_full.value.unshift(*@oldval)
          end
      end

      class PropertyUnshifted < PropertyPushed

          def undo
            locate_full.shift(@count)
          end
      end

      class PropertyPopped < PropertyDeleted
#         private
#           def initialize model, keypath, prevvals
#           end
        public
          def undo
            locate_full.value.push(*@oldval)
          end
      end

    private # Transaction methods

      def initialize model, sender = nil
        @stack = [] # UNSTABLE Qt::UndoStack.new ## cannot pass self (self) # super()
#         tag "tran test"
        raise ProtocolError, 'Protocol error, transaction already started' if @@transaction
#         tag "BEGIN WORK"
        @model, @sender, @@transaction = model, sender, self
        @attr_index = {}
        @committed = @aborted = false
        if block_given?
          begin
            begin
  #             tag "CALLING BLOCK with self #{self}"
              self == @@transaction or raise 'WTF???'
              yield self
            rescue Exception=>e
              if @@transaction
#                 tag "FAILED TO EXECUTE tranblock(#{e}, #{e.backtrace.join("\n")}), tran is now #{@@transaction}, abort unless nil"
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

      attr :model

      # call this to add more complex changes to the undostack
      def push propch
#         tag "Transaction#push(#{propch.inspect})"
        raise ProtocolError, 'Protocol error, no transaction' unless @@transaction
        @attr_index[propch.keypath] = propch
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
#         tag "create Propagation"
        model.propagateChange Propagation.new(@sender, @attr_index)
      ensure
        # free memory and blocks further operations
        @stack = @attr_index = nil
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
        @@transaction = @stack = @attr_index = nil
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

      # common case, for updates of single keypaths
      def addPropertyChange *keypath, oldval
#         tag "self = #{self}, @@transaction = #{@@transaction}, oldval=#{oldval}"
        keypath = keypath[0] if Array === keypath[0]
        push(oldval == PropertyChange::NoValue ? PropertyAdded.new(@model, keypath)
                                               : PropertyChange.new(@model, keypath, oldval))
      end

      # call this method to add pseudo changes. See TimeModel source for an example.
      # Adds the @last_property changed
      def addDependencyChange *index
        index = index[0] if Array === index[0]
        @attr_index[index] = @last_property
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

  will work as expected
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
          Transaction.new(@root, sender) do |tr|
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

      def propagateChange propagation
        (@observers ||= nil) and @observers.each do |o|
          o.updateModel self, propagation
        end
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
      def addObserver observer
        (@observers ||= []) << observer
      end

      def removeObserver observer
        @observers.delete observer
      end

=begin rdoc
      returns whether name may function as 'getter' on the model
      names like 'getX' are currently not supported.
      However, a proc can very well be a setter, where the object is
      passed as an argument.  This makes it possible to code the
      text or value to use in the gui, and not in the model.
=end
      def getter? name
        return true if name == :self || Proc === name
  #       tag "Does #{self.class}##{name} is a public method?"
        m = (public_method(name) rescue nil) or return
  #       tag "m.arity = #{m.arity}"
        -1 <= m.arity && m.arity <= 0
      end

      # To apply the getter, this method must be used.
      # Name should be a hashindex (pref. a Symbol), or an arrayindex (Fixnum)
      # The name +:self; is special.
      def apply_getter name
        return self if name == :self
        return name.call(self) if Proc === name
        return nil unless (m = public_method(name)) && -1 <= m.arity && m.arity <= 0
  #       tag "apply_getter #{name} to self == 'send'"
  #       if respond_to?(name)
        send name
  #       else
  #         send(name.to_s + '?')
  #       end
      end

  #     def method_missing symbol, *args, &block
  #       send name, *args, &block
  #     end

      def apply_setter name, value, sender = nil
        case name
        when :self
#           tag "apply_setter"
          # as an unwanted feature it will call 'postSetup' on self!!!!! FIXME(?)
          # setting the model will change the observers
          # FIXME: this is WRONG!  we may be within a transaction.
          Array.new(@observers || []).each do |o|
            raise 'DEPRECATED: observers'
  #           tag "Resetting model #{self} to observer #{o}"
            o.updateModel value, Propagation.new(sender, nil, true)
          end
        when Proc
          # ignore. Notice that setter? already returns false, but some bogo controls call this anyway
        else
          name = name.to_s
          name = name[0...-1] if name[-1] == '?'
          send(name + '=', value, sender)
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
        hash.each do |k, v|
  #         tag "send(#{k.inspect}, #{v.class} #{v})"
          send(k, v)
        end
      end

      def addTo parent, hash, &block
        parent.addModel self, hash, &block
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

      # grab a row
      def row(numric_idx)
        raise "#{self.class}#row is not implemented"
      end

      # iterate the rows
      def each
        return to_enum unless block_given?
        (0...length).each { |row| yield(self[row]) }
      end

      def [](idx)
        raise "#{self.class}#[] is not implemented"
      end

      def self.enum2i k
        k.is_a?(Qt::Enum) ? k.to_i : k
      end

  end # module Model

  # This class implements Model but is also a Control.
  class AbstractModel < Control
    include Model

    def length
      @qtc.rowCount
    end
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