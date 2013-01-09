
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
	def self.create_qt_signal s
	  '2' + s
	end

	# Note that using a hash or a block should not matter ONE YOTA
	# that's why we call the getters here, and expect them to be setters!
	def setupQuickyhash hash
	  #tag "setupQuickyhash(#{hash})"
	  for k, v in hash
	    case v
	    when Array
	      send k, *v
	    else
	      send k, v
	    end
	  end # for
	end # setupQuickyhash

	## the default calls new on klass, then addToParent on the result
	# It returns the instant.
	# NOTE: if addToParent can fail somehow it must delete itself
        def instantiate_child klass, parent
	  #tag "instantiate_child: #{klass}"
          r = klass.new 
	  begin
	    r.addToParent parent
	  rescue 
	    r.delete unless r.parent
	    raise
	  end
	  r
        end

      protected # methods of Object

	# the default assigns the parent
	def addObject child
	  child.parent = self
	end

	def setup hash = nil, &initblock
	  instance_eval(&initblock) if initblock 
	  setupQuickyhash hash if hash
	end # setup
      public # methods of Object

	## the default calls addObject 
	def addToParent parent
	  parent.addObject self
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

	# Like Enumerable and findChild, but it enumerates them
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
	  each = recursive ? include_root ? each_sub_with_root : each_sub
			   : include_root ? each_child_with_root : each_child 
	  for candidate in each 
	    yield(candidate) unless klass && !candidate.kind_of?(klass) ||  
				    name && candidate.objectName != name ||
				    block_given? && !yield(candidate)
	  end 
	end

	def self.signal *signals
	  for signal in signals
	    m = signal.to_s.sub(/\(.*/, '').to_sym # !
	    define_method m do |*args, &block|
	      signal_implementation m, signal, args, block
	    end
	  end
	end # signal

	signal 'destroyed(QObject *)'
    end  #class Object

  public # methods of R::Qt

end # module R::Qt
