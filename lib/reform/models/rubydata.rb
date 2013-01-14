
#  Copyright (c) 2013 Eugene Brazwick

require_relative '../model'

module R::Qt
  class RubyDataNode < BasicObject

      class String < self 

	#public # methods of String
      end # class String

      # wraps around Scalars.
      class Basic < self 

	#public # methods of Basic
      end # class Basic

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
	case value
	when ::Numeric, ::FalseClass, ::TrueClass, ::NilClass,
	     ::Symbol, ::Range, ::Regexp
	  value
	when ::String
	  value
	  # StringNode.new value # too costly ?? !
	else
	  raise NotImplementedError, "rubydata_wrap(#{value})"
	end
      end # rubydata_wrap

      # has the task to create the full keyvalue database 
      def self.rubydata_inter value, rubydata
	rubydata_wrap value
      end

    public # methods of RubyDataNode

      def model_apply_getter methodname
	# this only works for String and Basic
	@rubydata_value  
      end

      # override, delegate
      def class
	@rubydata_value.class
      end

      # override, delegate
      def instance_of? klass
	@rubydata_value.instance_of?(klass) || super
      end
  end # class RubyDataNode

  class RubyData < Model

      Node = RubyDataNode

    private # methods of RubyData

      def initialize *args
        super
	@rubydata_node = nil
      end

      def overwrite_with init_value
	@rubydata_node = Node::rubydata_inter init_value, self
      end

      def data value
	overwrite_with value
      end

    protected # methods of RubyData

      def model_apply_getter methodname
	case @rubydata_node
	when Node
	  @rubydata_node.model_apply_getter methodname
	when ::String
	  Node::String.new(@rubydata_node).model_apply_getter methodname
	else
	  # it is possible to reuse these instances.... a bit ugly though
	  Node::Basic.new(@rubydata_node).model_apply_getter methodname
	end
      end
  end # class RubyData

  Reform.createInstantiator __FILE__, RubyData
end # module R::Qt

