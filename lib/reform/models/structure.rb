
module Reform

require_relative '../model'
require_relative '../control'

=begin
=end
  class Structure < Control
    include Model

    private
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
      elsif @value.has_key?(symbol) && args.empty?
#         tag "applying #{symbol} to hash #{@value}"
        r = @value[symbol]
        if Hash === r then self.class.new(r, @grandparent) else r end
      else
        super
      end
    end

    def getter? name
      return true if name == :self || Proc === name
      @value.has_key?(name)
    end

    # To apply the getter, this method must be used.
    def apply_getter name
      return self if name == :self
      name.call(self) if Proc === name
#       tag "apply_getter #{name} to self == 'send'"
#       if respond_to?(name)
      r = @value[name]
      if Hash === r then self.class.new(r, @grandparent) else r end
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
end