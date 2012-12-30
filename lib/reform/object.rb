
require_relative '../urqtCore/liburqtCore' 

module Kernel
  private # methods of Kernel
    def tag msg
      # avoid puts for threading problems
      STDERR.print "#{File.basename(caller[0])} #{msg}\n"
    end # msg

end # module Kernel

module R::Qt

  ## 
  # This class supports constructing and setting up simple objects
  #
  # However:
  #	- slots/signals not supported 
  #	- no access to properties
  #	- events not supported
  #	- metaobject system not supported
  # 
  # Because I believe ruby can do all these things already.
  #
    class Object
      private # methods of Object
	# Note that using a hash or a block should not matter ONE YOTA
	# that's why we call the getters here, and expect them to be setters!
	def setupQuickyhash hash
	  tag "setupQuickyhash(#{hash})"
	  for k, v in hash
	    case v
	    when Array
	      send k, *v
	    else
	      send k, v
	    end
	  end # for
	end # setupQuickyhash

	def self.create_qt_signal s
	  '2' + s
	end

	def connect symbol, block
	  ((@proxies ||= {})[symbol] ||= []) << block
	end

	def emit symbol, *args, &block
	  @proxies and
	    proxies = @proxies[symbol] and
	      for proxy in proxies
		proxy[*args, &block]
	      end
	end

      public # methods of Object

	# guarantees free of the C++ instance.
	def scope 
	  yield self
	ensure
	  delete
	end # scope
      
	def self.signal *signals
	  for method in signals
	    define_method method do |*args, &block|
	      if block && args.empty?
		connect method, block
	      else
		emit method, *args, &block 
	      end
	    end
	  end
	end # signal
    end  #class Object

  public # methods of R::Qt

end # module R::Qt

# I decided to port QObject more or less complete.
# Since it should all work and most features are pretty handy!

if __FILE__ == $0
  include R
  o = Qt::Object.new
  # it has no name
  puts "o=#{o.inspect}, objectName='#{o.objectName}', to_s->#{o}"
  o.objectName = 'hallo'
  puts "objectName = #{o.objectName}, to_s->#{o}"
  # getters are also setters
  o.objectName 'Blurb'
  puts "objectName = #{o.objectName}"

  # we can pass a name, or a parent or a parameterhash in any order
  # and they execute in sequence
  frodo = nil 
  Qt::Object.new('fifi').scope do |fifi|
    puts "fifi.objectName = #{fifi.objectName}"
    # you can pass a block and it is executed in the context of the object
    froome = Qt::Object.new { objectName 'froome' }
    begin
      froome.parent = 'bart'
    rescue TypeError 
    end
    puts "froome.objectName = #{froome.objectName}"
    # And here we use a hash
    frodo = Qt::Object.new objectName: 'Frodo', parent: fifi
    puts "fifi.children = #{fifi.children}"
    puts "frodo = #{frodo}, frodo.parent=#{frodo.parent}"
    # we can replace all children, but a child can only have one parent
    froome.children frodo 
    puts "fifi.children = #{fifi.children}"
    puts "froome.children = #{froome.children}"
    puts "frodo.parent = #{frodo.parent}"
    froome.delete
    # deletes on zombies are ignored
    froome.delete
    puts "froome = #{froome}"
    puts "frodo = #{frodo}"
    frodo = Qt::Object.new objectName: 'Frodo', parent: fifi
    # now kill fifi and hence, frodo!
  end # scope
  puts "frodo = #{frodo}"
  # deletes on zombies are ignored
  frodo.delete
  frodo.delete
  begin
    frodo.objectName = 'death'
  rescue TypeError
  end
  Qt::Object.new(objectName: 'Fifi').scope do |fifi|
    frodo = Qt::Object.new objectName: 'Fifi', parent: fifi
    # children can be killed safely
    frodo.delete
    puts "fifi.children=#{fifi.children}"
  end

  # the signal and slot system, the code I wished I had:
  class Counter < Qt::Object
      def initialize value = 0
	super()
	@value = value 
      end

      attr_reader :value

      def value= v
	valueChanged @value = v
      end

      signal :valueChanged
  end

  counter = Counter.new 3
  counter2 = Counter.new
  counter.valueChanged { |v| counter2.value = v }
  # a disadvantage is that you cannot pass a block as a single argument to a
  # signal. In that case, use a lambda...
  # counter.valueChanged -> v { puts 'weird idea' }
  # Anyway, you should not use the signal like that.
  counter.value = 4
  puts "counter2.value = #{counter2.value}"
end # if
