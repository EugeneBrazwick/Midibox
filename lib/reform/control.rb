
require_relative 'object'

module R::Qt

  class Control < Object  # ie Qt::Object!
    private  # methods of Control
      # callback
      def parent2use4 child
	self
      end

      # handle_dynamics must move to C++ since it is required for many Qt 
      # classes as well!
      def handle_dynamics klass, method, options, *args, &block
	require_relative 'dynamic_attr'
	#tag "handle_dynamics #{method}->#{klass}"
	return apply_dynamic_getter method if args.empty? && !block
	case arg0 = args[0]
	when Hash, nil
	  attrib = DynamicAttribute.new self, klass, method, options, arg0, &block
	when Proc
	  if arg0.arity == 1
	    attrib = DynamicAttribute.new self, klass, method, options, connector: arg0
	  else
	    attrib = DynamicAttribute.new self, klass, method, options, arg0, &block
	  end
	else
	  apply_dynamic_setter method, *args
	end
      end

      alias :objectName_Object :objectName

      def apply_dynamic_getter method
	send method.to_s + '_get'
      end

    protected #methods of Control

      def apply_dynamic_setter method, *args
	send method.to_s + '=', *args
      end

      def connector value = nil, &block
	if z = value || block
	  @connector = z
	  want_data
	else
	  @connector
	end
      end

      # connect ourselves to the closest model upwards.
      # This includes self(?)
      def want_data path = []
	path.unshift self
	if @model
	  @model.model_add_listener path 
	elsif par = parent
	  par.want_data path
	else
	  raise Reform::Error, "no model found to connect to"
	end
      end

      def push_data value, sender = nil, path = []
	tag "#{self}::push_data(#{value})"
	sender ||= self
	path.unshift self
	if @model
	  @model.model_push_data value, sender, path 
	elsif par = parent
	  par.push_data value, sender, path
	end
      end

    public #methods of Control

      # the last method can in fact be an option-hash
      def self.attr_dynamic klass, *methods
	case methods[-1]
	when Hash
	  options = methods.pop
	else
	  options = nil
	end
	for method in methods
	  define_method method do |*args, &block|
	    handle_dynamics klass, method, options, *args, &block
	  end
	end
      end

      attr_dynamic String, :objectName

  end # class Control

end # module R::Qt

if __FILE__ == $0
  # controls can have dynamic arguments, these are Controls too.
  require_relative 'app'
  Reform::app {
  }
end
