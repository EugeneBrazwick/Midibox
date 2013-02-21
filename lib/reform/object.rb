
#  Copyright (c) 2013 Eugene Brazwick

require_relative 'liburqtCore' 

module Kernel
  private # methods of Kernel
    def tag msg
      # avoid puts for threading problems
      STDERR.print "#{File.basename(caller[0])} #{msg}\n"
    end # msg

end # module Kernel

module R
  module EForm 
      Size = Array
      Point = Array

      class Error < RuntimeError
      end
  end
end

Reform = R::EForm

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

      protected # methods of Object

	# the default assigns the QT(!) parent
	def addObject child
	  child.qtparent = self
	end # addObject

	# any object, except graphicsitem can have a model
	# this includes models. Delegating is more flexible
	def addModel child
	  model and raise Reform::Error, "object already has a model"
	  @model = child
	  addObject child
	end # addModel

      public # methods of Object

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

	alias :children_get :children

	# you can 'mount' a model into any object.
	attr :model

	## callback, called when a DynamicAttribute is given a 'connector'
	# Semantics: a RW-widget can decide to add a push-channel for data.
	# Erm...  See widgets/lineedit.rb to get the idea.
	def connect_attribute attrname, dynattr; end
	  # INCONVENIENT raise Reform::Error, "No support for connecting attribute #{self}::#{attrname}"

	# callback, called after the instance is parented
	def setup hash = nil, &initblock
	  instance_eval(&initblock) if initblock 
	  setupQuickyhash hash if hash
	end # setup

	## the default calls addObject 
	def parent= parent
	  parent.addObject self
	end

	# either parent_set or parent_get
	def parent parent = nil
	  if parent
	    #tag "#{self}.parent_set #{parent}"
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
