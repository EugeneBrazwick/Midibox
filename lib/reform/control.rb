
require_relative 'object'

module R::Qt

  class Control < Object  # ie Qt::Object!
    private  # methods of Control

      # handle_dynamics must move to C++ since it is required for many Qt 
      # classes as well!
      def handle_dynamics klass, method, options, *args, &block
	#tag "handle_dynamics #{method}->#{klass}"
	require_relative 'dynamic_attr'
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

      def collect_names v = nil
	return @collect_names if v == nil
	#tag "#{self}::@collect_names := #{v}"
	@collect_names = v
      end

      def use macro_id
	if macro = collector!.send(macro_id)
	  block = macro.block and instance_eval(&block)
	  quicky = macro.quicky and setupQuickyhash quicky
	end
      end

      def collector!
	collector or 
	  raise Reform::Error, "no collector found, please use 'collect_names true'"
      end

    protected #methods of Control

      # the closest parent (or self) which has collect_names true.
      def collector
	collect_names && self || (p = parent) && p.collector
      end

      def apply_dynamic_setter method, *args
	send method.to_s + '=', *args
      end

      # connect ourselves to the closest model upwards.
      # This includes self(?)
      def want_data path = []
	#tag "#{self}::want_data #{path.inspect}"
	path.unshift self
	if @model
	  @model.model_add_listener path 
	elsif par = parent
	  #tag "#{self}::want_data -> recurse into parent #{par}"
	  par.want_data path
	else
	  raise Reform::Error, "no model found to connect to"
	end
      end

      def push_data value, sender = nil, path = []
	#tag "#{self}::push_data(#{value})"
	sender ||= self
	path.unshift self
	if @model
	  @model.model_push_data value, sender, path 
	elsif par = parent
	  par.push_data value, sender, path
	end
      end

	# context: Control#objectName=
      def registerName name, child
	#tag "registerName(#{name})"
	m = method(name) rescue nil
	raise NameError, "the name '#{name}' is already in use" if m
	define_singleton_method name do
	  child
	end
      end # registerName

    public #methods of Control

      def trace_propagation v = nil
	return @trace_propagation if v.nil? 
	@trace_propagation = v
      end

      def connector value = nil, &block
	if z = value || block
	  @connector = z
	  want_data
	else
	  @connector
	end
      end

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


  class NoQtControl < Control
    protected # methods of NoQtControl
      # override. Because they are not QObjects in the first place
      def addObject child
	raise TypeError, "cannot add indiscrimate objects to a #{self.class}"
      end

    public # methods of NoQtControl

      def parent_get
	#tag "#{self}::parent_get @parent = #@parent"
        @parent
      end

      def objectName_get
        @objectName
      end

      # overrides
      attr_writer :objectName, :parent 

  end  # class NoQtControl
end # module R::Qt

if __FILE__ == $0
  # controls can have dynamic arguments, these are Controls too.
  require_relative 'app'
  Reform::app {
  }
end
