
module Reform

require_relative '../model'

=begin

Assuming we have a simple mapped array, how do we apply changes to the model using
insert delete and update of a single row?

It seems more appropriate to call connectModel 'updateModel' instead. Were we pass in
'options' what we actually changed since last time.
=end
  class SimpleModel < Control
    include Model, Enumerable

    private
    def initialize parent, qtc = nil, val = nil
      super(parent, qtc)
      value val         # this is OK...
    end

    # MAKES A MESS!!
#     def method_missing symbol, *args, &block
#       return super unless Kernel::const_defined?(:OpenStruct) && OpenStruct === @value
# #       tag "METHOD_MISSING #{symbol}"
#       @value.send symbol, *args, &block
#     end

    public

=begin
    we accept hash or array with elements that are models: el.is_a?(Model) yields true.
    or any object. In all cases we behave like an Enumerable of Models.

    However, a hash is an ambiguous thing.  Is it the list we are interested in,
    or maybe it is meant as a single record!

    So the new policy is to convert it to OpenStruct.
    Nice thing about OpenStruct, public_method will work on it.
    Maybe a special method like 'listvalue' could be used if a list is what you want
=end
    def value v = nil
      return @value if v.nil?
      if Hash === v
        require 'ostruct'
        @value = OpenStruct.new(v)
      else
        @value = v
      end
    end

    def length
      @value.respond_to?(:length) ? @value.length : 1
    end

    def each
      if @value.respond_to?(:each)
        @value.each do |entry|
          # we could reuse this wrapper, but that may be dangerous. This causes a bit of garbage.
          if entry.is_a?(Model)
            yield(entry)
          else
            yield(SimpleModel.new(nil, nil, entry))
          end
        end
      else
        yield(self)
      end
    end

    def getter? name
      return true if name == :self || Proc === name
      m = (@value.public_method(name) rescue nil) or return
#       tag "m.arity = #{m.arity}"
      -1 <= m.arity && m.arity <= 0
    end

    # To apply the getter, this method must be used.
    def apply_getter name
      return self if name == :self
      name.call(@value) if Proc === name
#       tag "apply_getter #{name} to self == 'send'"
#       if respond_to?(name)
      @value.send name
#       else
#         send(name.to_s + '?')
#       end
    end

    def setter?(name)
      return true if name == :self
      n = name.to_s
      n = n[0...-1] if n[-1] == '?'
      m = (@value.public_method(n + '=') rescue nil) or return
      -2 <= m.arity && m.arity <= 1
    end

    def apply_setter name, value
      if name == :self
        # as an unwanted feature it will call 'postSetup' on self!!!!! FIXME(?)
        # setting the model will change the observers
        Array.new(@observers || []).each do |o|
#           tag "Resetting model #{self} to observer #{o}"
          o.setModel value  # and not 'self'!!!
        end
      else
        name = name.to_s
        name = name[0...-1] if name[-1] == '?'
#         tag("Applying #{name}=() to #@value, using 'send'")
        @value.send(name + '=', value)
      end
    end

    attr_writer :value
  end

  createInstantiator File.basename(__FILE__, '.rb'), nil, SimpleModel

end