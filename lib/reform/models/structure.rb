
module Reform

require_relative '../model'
require_relative '../control'

=begin

Slightly simplistic and incomplete wrapper for anything simple, up to
arrays and hashes.

Hashes have read and write support for the [] and []= only!!!
Arrays were added later and support all writeops but for reading
only [] once again.

All unsupported methods will work but writes will not be noticed
by the model, and reads may return raw Array and Hash instances.

For simplistic JSON like operations it functions excelently, and missing
stuff can easily be implemented as the 'ArrayWrapper' shows.

In other words, it surely deserves the Nobel prize!
=end
  class Structure < Control
    include Model

    private

    class ArrayWrapper
      private
      def initialize grandparent, propname, ar
        @grandparent, @propname, @ar = grandparent, propname, ar
      end

      def self.def_single_delegators(accessor, *methods)
        methods.delete("__send__")
        methods.delete("__id__")
        for method in methods
          def_single_delegator(accessor, method)
        end
      end

      def self.def_single_delegator(accessor, method, ali = method)
        line_no = __LINE__; str = %{
          def #{ali}(*args, &block)
            begin
              #{accessor}.__send__(:#{method}, *args, &block)
              @grandparent.dynamicPropertyChanged @propname
            rescue Exception
              $@.delete_if{|s| %r"#{Regexp.quote(__FILE__)}"o =~ s} unless Forwardable::debug
              ::Kernel::raise
            end
          end
        }
        instance_eval(str, __FILE__, __LINE__)
      end

      public

      def_single_delegators :@ar, :[]=, :<<, :clear, :collect!, :compact!, :delete, :delete_at,
                                  :delete_if, :fill, :flatten!, :insert, :keep_if,
                                  :map!, :pop, :push, :reject!, :replace, :reverse!, :shift,
                                  :shuffle!, :slice!, :sort!, :uniq!, :unshift

      # next thing: all stuff returning array elements must wrap them, if they are a plain hash or
      # an array themselves...

      def [] *args
        case r = @ar.send(:[], *args)
        when Array then ArrayWrapper.new(@grandparent, @propname, r)
        when Hash then Structure.new(r, @grandparent)
        else r
        end
      end

      def method_missing sym, *args, &block
        @ar.send(sym, *args, &block)
      end
    end # class ArrayWrapper

    def initialize parent, qtc = nil
      if Hash === parent
#         tag "#{self}.new(#{parent.inspect}, gp=#{qtc}"
        super(nil)
        @grandparent = qtc || self
        value(parent)
      else
        super(parent, qtc)
        @grandparent = self
      end
    end

    def value v
      @value = v
    end

  public

    # MAKES A MESS!!
    def method_missing symbol, *args, &block
      return super unless @value
      if (nam = symbol.to_s)[-1] == '='
#         tag "applying #{symbol} to hash #{@value}, n='#{nam[0..-2]}'"
        symbol = nam[0...-1].to_sym
        @value[symbol] = args.size == 1 ? args[0] : args
#         tag "calling dynamicPropertyChanged for #{symbol}"
        @grandparent.dynamicPropertyChanged symbol
      else
        return super unless args.empty?
        symbol = symbol[0...-1].to_sym if symbol.to_s[-1] == '?'
        if @value.has_key?(symbol)
  #         tag "applying #{symbol} to hash #{@value}"
          case r = @value[symbol]
          when Hash then Structure.new(r, @grandparent)
          when Array then ArrayWrapper.new(@grandparent, symbol, r)
          else r
          end
        else
          nil
        end
      end
    end

    def getter? name
      return true if name == :self || Proc === name
      @value.has_key?(name)
    end

    # To apply the getter, this method must be used.
    def apply_getter name
#       tag "apply_getter(#{name})"
      return self if name == :self
      if Proc === name
        #applying method on the structure (not on hash)
        r = name.call(self)
#         tag "apply getter proc -> #{r.inspect}"
      else
        # take raw hash value
        r = @value[name]
      end
      # embellish it:
      case r
      when Hash then Structure.new(r, @grandparent)
      when Array then ArrayWrapper.new(@grandparent, name, r)
      else r
      end
    end

    def setter?(name)
      return true
    end

    def apply_setter name, value
      if name == :self
        super
      else
#         name = name.to_s
#         name = name[0...-1] if name[-1] == '?'
        @value[name] = value
        @grandparent.dynamicPropertyChanged name
      end
    end

  end

  createInstantiator File.basename(__FILE__, '.rb'), nil, Structure

end

if __FILE__ == $0
  require 'ostruct'
  t = OpenStruct.new x: 24, y: 'hallo', z: { a: 23, b: 'world', c: { d: 'even deeper' } }
  begin
    puts "t.x = #{t.x}, t.z.b = #{t.z.b}, t.z.c.d = #{t.z.c.d}"
    # you can't say t.z.b, it should be 't.z[:b]'
  rescue
    puts "EXPECTED ERROR: #{$!}"
  end
  class MyStructure < Reform::Structure
    def dynamicPropertyChanged name
      puts "dynamicPropertyChanged: '#{name}'"
      super
    end
  end
  t = MyStructure.new x: 24, y: 'hallo', z: { a: 23, b: 'world', c: { d: 'even deeper' } }
  puts "t.x = #{t.x}, t.z.b = #{t.z.b}, t.z.c.d = #{t.z.c.d}"
  # Still something is wrong, this does NOT send an 'update' message...  FIXED!
  t.z.c.d = 'pindakaas'
  puts "t.x = #{t.x}, t.z.b = #{t.z.b}, t.z.c.d = #{t.z.c.d}"
  t = MyStructure.new x: 24, y: [23, 'hallo', d: {i: :interesting}]
  puts "t.y.class = #{t.y.class}"
  puts "t.y[2].class = #{t.y[2].class}"
  puts "t.y[2].d.i = '#{t.y[2].d.i}'"
  t.y[2].d.i = :not
  puts "t.y[2].d.i is now '#{t.y[2].d.i}', and we were informed!"
end