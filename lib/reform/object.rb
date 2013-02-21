
#  Copyright (c) 2013 Eugene Brazwick

require_relative 'liburqtCore' 
require_relative 'r' 

module Kernel
  private # methods of Kernel
    def tag msg
      # avoid puts for threading problems
      STDERR.print "#{File.basename(caller[0])} #{msg}\n"
    end # msg

end # module Kernel

class Exception
  public # methods of Exception 
    def self.raise msg, caller = nil
      Kernel::raise self, msg, caller
    end
end

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

      # call-seq: new *args, &block
      # 
      # If an Object is passed it becomes the parent, and self is added to parent.children
      # If a String is passed it is assigned using objectName=.
      # If a Hash is passed it is passed to setupQuickyhash. :parent and :objectName are valid keys.
      # If block is given it is evaluated in the context of self.
      # 
	def initialize a0 = nil, a1 = nil, a2 = nil, &block
	  #tag "initialize(#{a0}, #{a1}, #{a2}, #{block})"
	  mark_ownership
	  if a0
	    initialize_arg a0
	    if a1
	      initialize_arg a1
	      a2 and initialize_arg a2
	    end
	  end
	  block and instance_eval(&block)
	end

	def self.create_qt_signal s
	  '2' + s
	end

	# Note that using a hash or a block should not matter ONE YOTA
	# that's why we call the getters here, and expect them to be setters!
	# Context: setup
	def setupQuickyhash hash
	  #tag "#{self}.setupQuickyhash(#{hash})"
	  for k, v in hash
	    case v
	    when Array
	      send k, *v
	    else
	      send k, v
	    end
	  end # for
	end # setupQuickyhash

	## the default calls new on klass, then parent on the result
	# It returns the instant.
	# NOTE: if parent can fail somehow it must delete itself
        def instantiate_child klass, parent
	  #tag "#{self}.instantiate_child: #{klass}, parent=#{parent}"
          r = klass.new 
	  begin
	    r.parent = parent
	  rescue 
	    r.delete unless r.parent_get
	    raise
	  end
	  r
        end

	def method_missing method, *arg
	  case method
	  # avoid iterating children for ruby internals:
	  when :to_ary, :to_str
	  else
	    m = method.to_s
	    #tag "#{self}::method_missing(#{m}), iterating each_child"
	    each_child do |child|
	      #raise FatalError, "programming error: objectName is sym???" if Symbol === child.objectName
	      #tag "child.objectName = #{child.objectName.inspect}, to_s='#{child.objectName.to_s.inspect}"
	      #tag "checking #{child} comp #{child.objectName.inspect} vs #{m.inspect}"
	      return child if child.objectName == m
	    end
	  end
	  super
	end

	# this is a shortcut to avoid	
	#    rubydata data: 4
	# you can now say:
	#    data 4
	def data arg
	  rubydata data: arg
	end

	# context: initialize
	def initialize_arg arg
	  #tag "initialize_arg(#{arg.inspect})"
	  case arg
	  when String, Symbol
	    self.objectName = arg
	  when Hash
	    setupQuickyhash arg
	  when R::Qt::Object
	    self.parent = arg
	  else
	    TypeError.raise "BAD argtype #{arg.class} for Object.new"
	  end
	end

	# context: Object::signal
	# with a block it delegates to 'connect', otherwise it delegates to 'emit'
	def signal_implementation methodname, signal, args, block
	  #tag "signal_implementation(#{methodname}, #{signal}, #{args.inspect}, #{block}"
	  if args.length == 1 && !block && Proc === args[0]
	    block, args = args[0], nil
	  end
	  if block
	    TypeError.raise "cannot use args with block" if args && !args.empty?
	    connect signal, block
	  else
	    args.unshift methodname
	    #tag "emit *#{args.inspect}"
	    emit *args
	  end
	  self
	end

      protected # methods of Object

	# the default assigns the QT(!) parent
	def addObject child
	  child.qtparent = self
	end # addObject

	# any object, except graphicsitem can have a model
	# this includes models. Delegating is more flexible
	def addModel child
	  model and Reform::Error.raise "object already has a model"
	  @model = child
	  addObject child
	end # addModel

      public # methods of Object

	def objectName name = nil
	  return objectName_get if name.nil?
	  self.objectName = name
	end

	# override
	def to_s
	  return 'zombie' if zombified?
	  name = objectName and "#{self.class}:'#{name}'" or super
	end

	def each_child &block
	  return to_enum :each_child unless block
	  #tag "calling #{self}.enqueue_children()"
	  enqueue_children &block
	end

	def each_child_with_root &block
	  return to_enum :each_child_with_root unless block
	  yield self
	  each_child &block
	end

	def each_sub
	  return to_enum :each_sub unless block_given?
	  queue = []
	  enqueue_children queue
	  while !queue.empty?
	    node = queue.shift
	    yield node unless node.synthesized?
	    node.enqueue_children queue
	  end
	end

	def each_sub_with_root &block
	  return to_enum :each_sub_with_root unless block
	  yield self
	  each_sub &block
	end

	# signal can be :symbol or 'qt_signal_str' Like 'validated(int)'
	def emit signal, *args
	  #tag "#{self}.emit #{signal.inspect} #{args.inspect}"
	  # block_given? is always true if called from EventSignalBroker::eventFilter()
	  # Even more the block looks like: (#<Proc:0x00000000000000>)
	  # BROKEN TypeError.raise "blocks (#{block.inspect}) cannot be passed to emit" if block_given?
	  if Symbol === signal
	    if @connections
	      proxylist = @connections[signal]
	      proxylist and proxylist.each do |proxy| 
		#tag "#{proxy}.call(*#{args.inspect})"
		proxy[*args] 
	      end
	    end
	    self
	  else
	    NotImplementedError.raise 'emitting qt-signals'
	  end
	end

	def qtobject?; true; end
	def synthesized?; end

	# it might be a better idea using 'each_child.to_a' here as well.
	# the idea is that each_child.to_a is relatively slow.
	def children 
	  each_child.to_a
	end

	# It is possible that a Qt::Object's parent is not a Qt::Object.
	# This is coded by setting @parent. This overrides any other parent.
	def parent_get 
	  @parent || qtparent_get
	end

	## callback, called when a DynamicAttribute is given a 'connector'
	# Semantics: a RW-widget can decide to add a push-channel for data.
	# Erm...  See widgets/lineedit.rb to get the idea.
	def connect_attribute attrname, dynattr; end
	  # INCONVENIENT raise Reform::Error, "No support for connecting attribute #{self}::#{attrname}"

	# callback, called after the instance is parented
	def setup hash = nil, &initblock
	  #tag "__FILE__ = #{__FILE__}"
	  instance_eval(&initblock) if initblock 
	  setupQuickyhash hash if hash
	end # setup

	## the default calls addObject 
	def parent= parent
	  parent.addObject self
	end

	# either parent= or parent_get
	def parent parent = nil
	  if parent
	    #tag "#{self}.parent= #{parent}"
	    self.parent = parent
	  else
	    #tag "#{self}.parent_get"
	    parent_get
	  end
	end

	# guarantees free of the C++ instance.
	def scope 
	  yield self
	ensure
	  delete
	end # scope

	# always recursive unless opts[:recursive] is false
	# if name is not a string and a block is passed 
	# we bypass the Qt system but use the same semantics.
	#
	# Options:
	#   - recursive, default true
	#   - include root, default false
        def findChild *args
	  #tag "findChild args=#{args.inspect}, block_given=#{block_given?}"
	  name = klass = opts = nil 
	  args.each do |arg|
	    #tag "testing arg #{arg}"
	    case arg
	    when Class then klass = arg
	    when Hash then opts = arg
	    else name = arg.to_str
	    end
	  end
	  recursive = opts ? opts[:recursive] : true
	  include_root = opts && opts[:include_root]
	  each = recursive ? include_root ? each_sub_with_root : each_sub
			   : include_root ? each_child_with_root : each_child 
	  #tag "klass=#{klass}, name=#{name}, block_given=#{block_given?}"
	  #tag "recursive=#{recursive}, include_root=#{include_root}"
	  #tag "each = #{each.to_a}"
	  for candidate in each 
	    #tag "testing #{candidate}"
	    return candidate unless klass && !candidate.kind_of?(klass) ||  
				    name && candidate.objectName != name ||
				    block_given? && !yield(candidate)
	  end 
	end

	# Like Enumerable 
        def find_all *args
	  return enum_for(:find_all) if args.empty? && !block_given?
	  name = klass = opts = nil 
	  args.each do |arg|
	    case arg
	    when Class then klass = arg
	    when Hash then opts = arg
	    else name = arg.to_str
	    end
	  end
	  recursive = opts ? opts[:recursive] : true
	  include_root = opts && opts[:include_root]
	  enum = recursive ? include_root ? each_sub_with_root : each_sub
			   : include_root ? each_child_with_root : each_child 
	  r = []
	  enum.each do |candidate|
	    r << candidate unless klass && !candidate.kind_of?(klass) ||  
				  name && candidate.objectName != name ||
				  block_given? && !yield(candidate)
	  end 
	  r
	end

	# for each signal it creates a method with the name of the signal.
	# You can pass the method arguments and it calls 'emit'
	# Or you can pass it a block and it calls 'connect'.
	#
	# signal 'valueChanged(int)'
	#
	# valueChanged { |val| puts "value became #{val}" }
	# valueChanged { |val| $app.quit }
	# valueChanged(44)
	#
	# More than one block can be connected and they will all be executed.
	# Signal can be a Qt signal, or it can be any ruby symbol.
	#
	def self.signal *signals
	  for signal in signals
	    m = signal.to_s.sub(/\(.*/, '').to_sym # !
	    #tag "define method :#{m} for signal '#{signal}'"
	    if method_defined? m
	      NameError.raise "the signal #{self}.#{m} is already defined as " +
			      "#{instance_method(m).owner}.#{m}"
	    end
	    define_method m do |*args, &block|
	      #tag "signal received. m=#{m.inspect}, signal=#{signal}, args=#{args.inspect}"
	      #tag "block=#{block}"
	      signal_implementation m, signal, args, block
	    end
	  end
	end # signal

	#override, this disables dup and clone on QObject.
	# Which will cause disasters, since a ruby ref has a 1 on 1 relationship with a QObject
	# We should make a deep copy, but I don't believe Qt supports that.
	def initialize_copy other
	  Reform::Error.raise "Qt objects cannot be duplicated or cloned"
	end

	signal 'destroyed(QObject *)'


	# you can 'mount' a model into any object.
	attr :model

	alias children_get children
	alias qtchildren qtchildren_get
	alias name objectName
	alias each each_child

    end  #class Object

  public # methods of R::Qt

end # module R::Qt
