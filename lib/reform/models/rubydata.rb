
#  Copyright (c) 2013 Eugene Brazwick

require_relative '../model'
require 'forwardable'

module R::Qt
  class RubyDataNode < BasicObject

      class String < self 

	#public # methods of String
      end # class String

      # wraps around Scalars.
      class Basic < self 

	public # methods of Basic
	  def to_str
	    if @rubydata_value == nil
	      # this occurs often for unintialized data. 
	      ''
	    else
	      @rubydata_value.to_str
	    end
	  end
      end # class Basic

      # @rubydata_value is a ::Hash
      class Hash < self

	private # methods of Hash

	  def initialize hash
	    super
	    hash.each do |k, v|
	      raise ReformError, "non atomic hash key in model" unless RubyDataNode::rubydata_atomic?(k)
	      hash[k] = RubyDataNode::rubydata_inter v
	    end
	  end # initialize

	public # methods of Hash

	  # override
	  def model_rowCount
	    @rubydata_value.length
	  end

	  # model_row is inconvenient but required since Qt 'cursors' 
	  # can only handle row+col seqnrs
	  def model_data i
	    @rubydata_value.each_with_index do |kv, idx|
	      return RubyDataNode::rubydata_node(@rubydata_value[kv[0]]) if idx == i
	    end
	  end # model_data

	  def model_data2index data
	    @rubydata_value.each_with_index do |kv, idx|
	      return idx if kv[1] == data
	    end
	    -1
	  end # model_data2index

	  def model_key2data key
	    RubyDataNode::rubydata_node @rubydata_value[key]
	  end # model_key2data

	  def model_index2key i
	    @rubydata_value.each_with_index do |kv, idx|
	      return kv[0] if idx == i
	    end
	  end # model_index2key

	  def model_key2index key
	    @rubydata_value.each_with_index do |kv, idx|
	      return idx if kv[0] == key
	    end
	    -1
	  end
      end # class Hash

      # @rubydata_value is an ::Array
      class Array < self

	private # methods of Array

	  def initialize ary
	    super
	    ary.each_with_index do |v, k|
	      ary[k] = RubyDataNode::rubydata_inter v
	    end
	  end # initialize

	public # methods of Array

	  # override
	  def model_rowCount
	    @rubydata_value.length
	  end

	  #override
	  def model_data i
	    RubyDataNode::rubydata_node @rubydata_value[i]
	  end

	  def model_data2index data
	    @rubydata_value.each_with_index do |el, idx|
	      return idx if el == data
	    end
	    -1
	  end
      end # class Array

      # wraps around any non-atomic object.
      class Object < self
	private # methods of Object

	  def initialize obj
	    super
	    obj.instance_variables.each do |iv|
	      v = obj.instance_variable_get iv
	      unless RubyDataNode::rubydata_atomic? v
		obj.instance_variable_set iv, (RubyDataNode::rubydata_inter v)
	      end
	    end # each iv
	  end #initialize

	public # methods of Object

      end

      # still missing, the special case:  ModelWithOwnStorage
      
    private # methods of RubyDataNode

      def initialize value
	@rubydata_value = value
      end #initialize

    protected # methods of RubyDataNode

      # Strings are not wrapped here.
      # Because this is called by rubydata_inter. This means the 
      # full tree is converted and every plain String would require an
      # additional instance.
      # We can use a special 'reusable' instance. Or a new one
      # just when the node is being retrieved!
      def self.rubydata_wrap value
	#tag "rubydata_wrap(#{value})"
	return value if rubydata_atomic?(value)
	case value
	when ::Array
	  #tag "using ARRAY"
	  Array.new value
	when ::Hash
	  #tag "using HASH"
	  Hash.new value
	else
	  Object.new value
	end
      end # rubydata_wrap

      # has the task to create the full keyvalue database 
      def self.rubydata_inter value
	rubydata_wrap value
      end

    public # methods of RubyDataNode

      def method_missing sym, *args
	# BAD IDEA tag "METHOD MISSING :#{sym}"	      OBVIOUSLY RubyDataNode has NO METHOD 'tag' EITHER!!!!!
	if sym == :respond_to?
	  false
	else
	  #$stderr.puts "METHOD MISSING :#{sym}"
	  @rubydata_value.send sym, *args
	end
      end

      def self.rubydata_atomic? value
	case value
	when ::Numeric, ::FalseClass, ::TrueClass, ::NilClass,
	     ::Symbol, ::Range, ::Regexp, ::String
	  true
	else
	  false
	end
      end

      def model_value
	@rubydata_value
      end
      
      def model_rowCount
	1
      end

      def model_data _i
	RubyDataNode::rubydata_node @rubydata_value
      end

      def model_index2key i
	i
      end

      def model_data2index _data
	0
      end

      def model_key2data key
	model_data key
      end

      def model_key2index key
	key
      end

      def model_apply_getter methodname
	tag "RubyDataNode::model_apply_getter(:#{methodname})"
	if methodname == :self
	  @rubydata_value
	else
	  @rubydata_value.send methodname  
	end
      end

      def model_apply_setter methodname, value, sender
	@rubydata_value.send "#{methodname}=", value
      end
      #       alias real_class class	BasicObject has none!!

      # NOT an override, delegate
      def class
	@rubydata_value.class
      end

      # override, delegate
      def instance_of? klass
	@rubydata_value.instance_of?(klass) || super
      end
      
      def to_s
	'&{' + @rubydata_value.class.to_s + ':' + @rubydata_value.to_s + '}'
      end

      def inspect
	'&<' + @rubydata_value.class.to_s + ': ' + @rubydata_value.inspect + '>'
      end

      def self.rubydata_node node
	#tag "node.class = #{node.class}"
	case node
	when RubyDataNode
	  node
	when ::String
	  String.new node
	else
	  #tag "creating new Scalar"
	  # it is possible to reuse these instances.... a bit ugly though
	  Basic.new node
	end
      end # rubydata_node
  end # class RubyDataNode

  ## this class wraps around any ruby data (with some limitations)
  # It can be used using the 'rubydata' instantiator (as all controls)
  # or the shortcut: 'data' can be used instead:
  #	data X  
  # is the same as:
  #     rubydata { data X }
  #
  class RubyData < Model
    extend Forwardable

      # so RubyDataNode == RubyData::Node
      Node = RubyDataNode

    private # methods of RubyData

      def initialize *args
        super
	@rubydata_node = nil
      end

      def overwrite_with init_value
	#tag "overwrite_with(#{init_value.inspect})"
	@rubydata_node = Node::rubydata_inter init_value
      end

      def data *value
	value = value[0] if value.length == 1
	overwrite_with value
      end

	# always returns a Node
      def rubydata_node
	Node::rubydata_node @rubydata_node
      end

    protected # methods of RubyData

    public # methods of RubyData

      alias self= overwrite_with

      def inspect
	super + "[#{@rubydata_node.inspect}]"
      end

      def model_apply_getter method
	#tag "RubyData::model_apply_getter(:#{method}), NODE=#{@rubydata_node.inspect}"
	if Node === @rubydata_node
	  @rubydata_node.model_apply_getter method
	elsif method == :self
	  @rubydata_node
	else
	  @rubydata_node.send method
	end
      end

      def_delegators :rubydata_node, # delegator!
		     :model_rowCount, :model_data,
		     :model_data2index, :model_key2data, :model_index2key, 
		     :model_key2index
     
      def model_apply_setter method, value, sender
	if method == :self
	  overwrite_with value
	elsif Node === @rubydata_node
	  @rubydata_node.model_apply_setter method, value, sender
	else
	  @rubydata_node.send "#{method}=", value
	end
      end

  end # class RubyData

  Reform.createInstantiator __FILE__, RubyData
end # module R::Qt

