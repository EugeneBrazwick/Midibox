
# Copyright (c) 2010 Eugene Brazwick

require 'continuation'
require 'Qt'

# extend the Binding class with 'of_caller'
class Binding

#   private
#     def self.createcc(*args, &block) # :nodoc:
#       cc = nil; result = Kernel::callcc {|c| cc = c; block.call(cc) if block and args.empty?}
#       result ||= args
#       return *[cc, *result]
#     end

  public

# This method returns the binding of the method that called your
# method. It will raise an Exception when you're not inside a method.
#
# It's used like this:
#   def inc_counter(amount = 1)
#     Binding.of_caller do |binding|
#       # Create a lambda that will increase the variable 'counter'
#       # in the caller of this method when called.
#       inc = eval("lambda { |arg| counter += arg }", binding)
#       # We can refer to amount from inside this block safely.
#       inc.call(amount)
#     end
#     # No other statements can go here. Put them inside the block.
#   end
#   counter = 0
#   2.times { inc_counter }
#   counter # => 2
#
# Binding.of_caller must be the last statement in the method.
# This means that you will have to put everything you want to
# do after the call to Binding.of_caller into the block of it.
# This should be no problem however, because Ruby has closures.
# If you don't do this an Exception will be raised. Because of
# the way that Binding.of_caller is implemented it has to be
# done this way.

    def self.of_caller(&block)
    #   old_critical = Thread.critical
    #   Thread.critical = true
      count = 0
      armed = false

      restart_cc = result = error = nil

      tracer = lambda { |*args|
#         puts "TRACER???"
        puts ":TRACER, armed=#{armed}, count=#{count}, type = #{args[0]}, context = #{args[4]}, extra_data = #{args}, self = #{eval('self', args[4])}"
        if armed
            # It would be nice if we could restore the trace_func
            # that was set before we swapped in our own one, but
            # this is impossible without overloading set_trace_func
            # in current Ruby.
          Thread.current.set_trace_func(nil)
          tag "SWITCHED off tracing"
          result = args[4]
          restart_cc.call
        end
        type, extra_data = args[0], args
=begin
Normal case:
c-return    set_trace_func
line        of_caller: cc.call(context, nil)
return1     of_caller
return2     callee
return3     callee of callee. Only there is context.self identical to the caller?
=end
        if type == "return"
          count += 1
          # First this method and then calling one will return --
          # the trace event of the second event gets the context
          # of the method which called the method that called this
          # method.
          armed = true if count == 2
          # and the next trace will have the correct context
        elsif type == "line" then
          nil
        elsif type == "c-return" and args[3] == :set_trace_func then
          nil
        else
          Thread.current.set_trace_func(nil)
          tag "SWITCHED off tracing"
          error = "Binding.of_caller used in non-method context or " +
                  "trailing statements of method using it aren't in the block."
          cc.call
        end
      }

      # How does a cc work? If callcc is called it passed the cc as the arg.
      # We assign that to cc. callcc returns nil. And that's only where it begins.
      # We can now call the cc and we will the jump back to assignment, where
      # the parameters of the cc.call are returned.
      callcc {|continuation| restart_cc = continuation }
      tag "did callcc, or jumped here. result = #{result}"
      if result
        yield(result)
      elsif error
        raise ArgumentError, error
      else
=begin
Next stage. We got our 'cc'. We now start tracing methods by installing a
tracer and return. The deal is our caller also returns.
This is then caught here, and we call the cc at precisely the right time.
At that point we have access to the binding of the caller, since it is
passed to cc and returned into 'result' and it goes into the block with yield.
=end
        tag "setting trace func to #{tracer.inspect}"
        Thread.current.set_trace_func tracer
#         tag "returning nil"
        return nil
      end
  #     Thread.critical = old_critical
    end  # of_caller
end # class Binding

module Reform

=begin
  the Propagation class is used when data is emitted from a datasource, due to a change,
  or initialization.

  Receivers of the data can inspect it to see if they can do anything usefull with it.

  The Control class dispatches the notification through two methods
    update_model, and propagate.
  Update model informs a control, and propagate informs its children.
  The sender of a notification never receives the notification itself.
  Only controls that 'want_data?' will receive the update_model and propagate
  methods.
  If a control has another model (external, so not the data within a combobox)
  set, then it will never receive propagations from outside its tree.

  Only Frame can have a model set. A widget can have two frames with completely independend
  models.

=end
  class Propagation
    private
      def initialize sender, attrs_changed, init = false
        @sender, @attrs_changed, @init = sender, attrs_changed, init
      end

    public
      attr :sender, :attrs_changed

      def changed? connector
        case connector
        when Symbol then @init || @attrs_changed[connector]
        else
          tag "Unhandled connector type #{connector}"
          true
        end
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

      class PropertyChange < Qt::UndoCommand
      private
        def initialize model, propname, oldval
          super()
          # note this clone may tragically fail for many Qt classes....
          @model, @propname = model, propname
            # To be sure the abort returns the exact original state
            # we cannot use clone.
            # Unfortunately this implies the value can be altered
            # outside the transaction.
            # Oh well,..... Don't do that then!
#           case oldval
#           when Fixnum
            @oldval = oldval
#           else
#             @oldval = oldval.clone
#           end
        end

      public
        def undo
          @model.apply_setter @propname, @oldval
        end
      end # class PropertyChange

    private

      def initialize model, sender
#         tag "CALLING super"
        @stack = Qt::UndoStack.new # super()
#         tag "tran test"
        raise tr('Protocol error, transaction already started') if @@transaction
#         tag "BEGIN WORK"
        @model, @sender, @@transaction = model, sender, self
        @attrs_changed = {}
        @committed = @aborted = false
        if block_given?
          begin
#             tag "CALLING BLOCK with self #{self}"
            self == @@transaction or raise 'WTF???'
            yield self
#             tag "EXECUTED tranblock, tran is now #{@@transaction}, commit unless nil"
            commit if @@transaction
          rescue
            abort if @@transaction
            raise
          end
        end
      end

    public

      attr :model

      def self.transaction
#         tag "self.transaction, t = #{@@transaction}"
        @@transaction
      end

      def commit
#         tag "#{self}.COMMIT WORK, @@tran= #{@@transaction}, aborted=#@aborted, sender = #@sender"
        raise tr('Protocol error, no transaction to commit') unless @@transaction
        raise tr('Protocol error, transaction inactive') if @aborted || @committed
        model.propagateChange Propagation.new(@sender, @attrs_changed)
        @stack.clear
        @@transaction = nil
        @committed = true
      end

      def abort
        tag "#{self}.ABORT WORK, aborted := true, globtran=#{@@transaction}, sender = #@sender"
        raise tr('Protocol error, no transaction to abort') unless @@transaction
        raise tr('Protocol error, transaction inactive') if @aborted || @committed
        @aborted = true
        # FIRST destroy the undo's since they will call apply_setter
        @stack.setIndex 0
        @stack.clear
        @@transaction = nil
      end

      def aborted?
        @aborted
      end

      def addPropertyChange name, oldval
#         tag "self = #{self}, @@transaction = #{@@transaction}"
        raise tr('Protocol error, no transaction') unless @@transaction
        @attrs_changed[name] = true
        @stack.push PropertyChange.new(@model, name, oldval)
      end
  end

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
    private

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
              if tran = Transaction.transaction
                # Existing tran. Note it may be a tran aborting, and resetting our data
                # in that case, do not change anything.
                tran.addPropertyChange(attrsym, prev) unless tran.aborted?
                instance_variable_set(attr, value)
              else
                tag "Calling Transaction.new(#{self}, sender=#{sender}"
                Transaction.new(self, sender) do |tr|
#                   tr or raise 'WTF'
#                   tag "tr = #{tr}, tran = #{Transaction.transaction}"
#                   tr == Transaction.transaction or raise 'WTF2'
                  tr.addPropertyChange(attrsym, prev)
                  instance_variable_set(attr, value)
                end
              end
#             end # Binding
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
#           def contextsToUse
#             [ModelContext, App]
#           end

          def parent_qtc(*)
          end

      end # ClassMethods

    # override
      def self.included mod
  #       tag "Included by #{mod}"
        mod.extend ClassMethods
      end

    public

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
#       def model?
#         true
#       end

      # Control compatibility
      def widget?
      end

      # observers are always ReForms, currently
      def addObserver_i observer
        (@observers ||= []) << observer
      end

      def removeObserver_i observer
        @observers.delete observer
      end

      # note that the :property option is not yet implemented. This can also be an array with symbols
      def dynamicPropertyChanged name
        raise 'DEPRECATED'
  #       tag "#{self} name=#{name}, no_dynamics = #{@no_dynamics||=false}, observers=#{(@observers ||= []).inspect}"
        return if instance_variable_defined?(:@no_dynamics) && @no_dynamics
        (@observers ||= nil) and @observers.each do |o|
  #         tag "Propagating model #{self} to observer #{o}"
          o.updateModel self, property: name
        end
      end

      alias :dynamic_property_changed :dynamicPropertyChanged

      # switch of propagation, within the block passed. DEPRECATED.
      def no_dynamics
        raise 'DEPRECATED'
        @no_dynamics = true
        yield
      ensure
        remove_instance_variable(:@no_dynamics)
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
        if name == :self
#           tag "apply_setter"
          # as an unwanted feature it will call 'postSetup' on self!!!!! FIXME(?)
          # setting the model will change the observers
          Array.new(@observers || []).each do |o|
  #           tag "Resetting model #{self} to observer #{o}"
            o.updateModel value, Propagation.new(sender, nil, true)
          end
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
        return true if name == :self
        n = name.to_s
        n = n[0...-1] if n[-1] == '?'
        m = (public_method(n + '=') rescue nil) or return
        -2 <= m.arity && m.arity <= 1
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
      def transaction(sender = nil, &block)
        return Transaction.transaction unless block
#         tag "Sender = #{sender}" # ie, the creator of the transaction
        Transaction.new(self, sender, &block)
      end

      # usefull for array like models. If only a single row is present, just return 1
      def length
        raise "#{self.class}#length is not implemented"
      end

      def empty?
        length == 0
      end

      # grab a row
      def [](idx)
        raise "#{self.class}#[] is not implemented"
      end

      # iterate the rows
      def each
        return to_enum unless block_given?
        (0...length).each { |row| yield(self[row]) }
      end

      def self.enum2i k
        k.is_a?(Qt::Enum) ? k.to_i : k
      end

  end # module Model

  class AbstractModel < Control
    include Model
  end

end # module Reform

if __FILE__ == $0
  require 'reform/app'  # for tag method
  include Reform

#   tag "TAG ?? "
=begin
  set_trace_func -> *args { puts "TRACE: #{args}" }
  tag "First trace"
  set_trace_func(nil)

  set_trace_func -> *args { puts "TRACE: #{args}" }
  tag "Switched tracing on once more"
  set_trace_func(nil)

  WORKING FINE
=end
  class A
    def a
      tag "arrived in A.a"
      Binding.of_caller do |binding|
        puts "caller = #{eval('self', binding)}"
      end
      # EMPTY !!
    end
  end

  class B
    def b
      A.new.a
      puts "hm, does this work then??"
    end
  end

  B.new.b

  tag "Can we repeat it?"
  B.new.b

  set_trace_func lambda { |*args| puts "TRACE: #{args}" }
  tag "Does set_trace_func even work now???"
  set_trace_func(nil)

# exit 0
#   tag "Calling A.new.a from the main"
#   A.new.a

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
    s = SimpleStruct.new
    s.field = 45
    s.transaction(self) do
      s.field = 24
      tag "AND now expect prop:"
    end
    s = SimpleStruct.new
    s.transaction(self) do |tran|
      raise 'WTF' unless tran == Transaction.transaction
      s.field = 82324
      raise 'WTF' unless tran == Transaction.transaction
      tag "AND now expect no prop:"
      tran.abort
      tag "s.field #{s.field} should be restored to 24"
      raise 'WTF' unless s.field == 24
    end
  end

  test

end # test case