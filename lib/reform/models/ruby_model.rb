
module Reform

require_relative '../model'

=begin

Assuming we have a simple mapped array, how do we apply changes to the model using
insert delete and update of a single row?

It seems more appropriate to call connectModel 'updateModel' instead. Were we pass in
'options' what we actually changed since last time.
=end
  class SimpleModel < AbstractModel
    include Enumerable

    private

      def initialize parent, qtc = nil, val = nil
        super(parent, qtc)
        value val         # this is OK...
      end

    public

=begin
    we accept hash or array with elements that are models: el.is_a?(Model) yields true.
    or any object. In all cases we behave like an Enumerable of Models.

    However, a hash is an ambiguous thing.  Is it the list we are interested in,
    or maybe it is meant as a single record!

    So the new policy is to use 'structure' for simple non-list like hashes
=end
      def value v = nil
        return @value if v.nil?
        @value = v
#         tag "SimpleModel#value(value := #{v.inspect}, Enumerable?=#{Enumerable===@value})"
        @key2index = @index2key = nil
        if Enumerable === @value
          @key2index = {}
          if @value
            to_invert = if Hash === @value then @value.keys else @value end
            to_invert.each_with_index do |v, idx|
              key = Model::enum2i(v.respond_to?(:key) ? v.key : v)
              @key2index[key] ||= idx
            end
          end
          @index2key = @key2index.invert
        end
#         tag "key2index = #{@key2index.inspect}"
#         tag "index2key = #{@index2key.inspect}"
      end

      def length
        @value.respond_to?(:length) ? @value.length : 1
      end

      def empty?
        return @value.empty? if @value.respond_to?(:empty?)
        !@value.respond_to?(:length) || @value.length == 0
      end

      # Qt fetches data by row. So idx is always an integer
      def [](idx)
        case @value
        when Array then @value[idx]
        when Hash then @value[@index2key[idx]]
        else
          if @value.respond_to?(:[]) then @value[idx] else @value end
        end
      end

        # returns the models value at given numeric index
      def data_at idx
        if Hash === @value then @index2key[idx] else @value[idx] end
      end

        # this should imply that 'each_pair' is to be used.
      def hasKeys?
        tag "hasKeys #@value -> #{Hash === @value}"
        Hash === @value
      end

      def keys
        @value.keys
      end

      # this is not necessarily valid
      def each_pair(&block)
        @value.each_pair(&block)
      end

      # this 'each' also gives us 'each_with_index'
      def each(&block)
        if @value.respond_to?(:each)
          @value.each(&block)
        else
          block.call(self)
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
        return @value if name == :self
        name.call(@value) if Proc === name
        @value.send name
      end

      def setter?(name)
        return true if name == :self
        n = name.to_s
        n = n[0...-1] if n[-1] == '?'
        m = (@value.public_method(n + '=') rescue nil) or return
        -2 <= m.arity && m.arity <= 1
      end

      def apply_setter name, value, sender
        if name == :self
          @value = value
          super name, self, sender
        else
          name = name.to_s
          name = name[0...-1] if name[-1] == '?'
#           tag("Applying #{name}=() to #@value, using 'send'")
          @value.send(name + '=', value, sender)
          # and this assumes this a dynamic property (how can that be? ??) ???????
        end
      end

      attr_writer :value

      def self.value2key value
        Model::enum2i(value.respond_to?(:key) ? value.key : value)
      end

      def value2index value
#         tag "value2index(#{value}) -> key #{SimpleModel::value2key(value).inspect}"
#         tag "@key2index=#{@key2index.inspect}. Since @value = #@value"
        if @key2index then @key2index[SimpleModel::value2key(value)] else 0 end
      end

  end # class SimpleModel

  createInstantiator File.basename(__FILE__, '.rb'), nil, SimpleModel

end