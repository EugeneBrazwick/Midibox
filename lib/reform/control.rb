
require_relative 'object'

module R::Qt

  class Control < Object  # ie Qt::Object!
    private  # methods of Control

      def get_klass options
	require_relative 'dynamic_attr'
	dyn_attr_required = options && options[:require] and
	  require_relative dyn_attr_required 
	options && options[:klass] || DynamicAttribute
      end # get_klass

      # handle_dynamics must move to C++ since it is required for many Qt 
      # classes as well!
      def handle_dynamics klass, method, options, *args, &block
	#tag "#{self.class}::handle_dynamics :#{method}->#{klass}, arg0=#{args[0].inspect}"
	if args.empty? && !block
	  #tag "just get the value, delegate to apply_dynamic_getter(:#{method})"
	  apply_dynamic_getter method 
	else
	  #tag "dyn_attr_klass = #{dyn_attr_klass}"
	  case arg0 = args[0]
	  when Hash, nil
	    get_klass(options).new self, klass, method, options, arg0, &block
	  when Proc
	    if arg0.arity == 1
	      get_klass(options).new self, klass, method, options, connector: arg0
	    else
	      get_klass(options).new self, klass, method, options, arg0, &block
	    end
	  else
	    #tag "just set the value, delegate to apply_dynamic_setter(:#{method})"
	    apply_dynamic_setter method, *args
	  end
	end
      end # handle_dynamics

      alias :objectName_Object :objectName

      def apply_dynamic_getter method
	#tag "apply_dynamic_getter :#{method}"
	send method.to_s + '_get'
      end # apply_dynamic_getter

      def collect_names v = nil
	return @collect_names if v == nil
	#tag "#{self}::@collect_names := #{v}"
	@collect_names = v
      end # collect_names

      def use macro_id
	if macro = collector!.send(macro_id)
	  block = macro.block and instance_eval(&block)
	  quicky = macro.quicky and setupQuickyhash quicky
	end
      end # use

      def collector!
	collector or 
	  raise Reform::Error, "no collector found, please use 'collect_names true'"
      end # collector!

    protected #methods of Control

      # the closest parent (or self) which has collect_names true.
      def collector
	collect_names && self || (p = parent) && p.collector
      end # collector

      def apply_dynamic_setter method, *args
	#tag "#{self}::apply_dynamic_setter :#{method}"
	send method.to_s + '=', *args
      end # apply_dynamic_setter

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
	  raise Reform::Error, "no model found to connect to, path collected: #{path.inspect}, at #{self}"
	end
      end # want_data

	# note that propagation can be dumped by specifying 'trace_propagation true' in the sender cq widget
      def push_data value, path = []
	#tag "#{self}::push_data(#{value})"
	path.unshift self
	if @model
	  #tag "delegate #{value}  to @model #@model"
	  @model.model_push_data value, path 
	elsif par = parent
	  #tag "delegate to parent"
	  par.push_data value, path
	end
      end # push_data

	# context: Control#objectName=
      def registerName name, child
	#tag "registerName(#{name})"
	if respond_to? name
	  raise NameError, "the name '#{name}' is already in use"
	end
	define_singleton_method name do
	  child
	end
      end # registerName

    public #methods of Control

      # override
      def objectName= newname
	super newname
	newname && (c = collector) and c.registerName newname, self
      end

      def addDynamicAttribute attr
	addObject attr
      end # addDynamicAttribute

      def trace_propagation v = nil
	return @trace_propagation if v.nil? 
	@trace_propagation = v
      end # trace_propagation

      def connector value = nil, &block
	if z = value || block
	  @connector = z
	  want_data
	else
	  @connector
	end
      end # connector

      ## :call-seq:   attr_dynamic type, :meth1 [,:meth2...] [, optionhash]
      # 'type' refers to the attribute, so String if it is a string.
      # This typing is required for Qt and also to create a proper default value.
      def self.attr_dynamic klass, *methods
	#tag "#{self}.attr_dynamic #{klass} #{methods.inspect}"	  # INTERESTING
	options = Hash === methods[-1] ? methods.pop : nil
	with_acceptors = options && options[:with_acceptors]
	methods.each do |meth|      # NOT 'for' GODDAMNED!
	  #tag "creating method :#{method}"
	  if method_defined? meth
	    NameError.raise "the dynamic attribute #{self}.#{meth} is already defined as " +
			    "#{instance_method(meth).owner}.#{meth}"
	  end
	  define_method meth do |*args, &block|
	    handle_dynamics klass, meth, options, *args, &block
	  end
	  if with_acceptors
	    assigner = (meth.to_s + '=').to_sym
	    #tag "creating acceptor :#{assigner}"
	    define_method assigner do |value|
	      #tag "executing acceptor :#{assigner}(#{value})"
	      apply_dynamic_setter meth, value
	    end
	  end # with_acceptors
	end # each
	#tag "OK"
      end # attr_dynamic

      # attr_dynamic String, :objectName

      alias collectnames collect_names
  end # class Control


  ## Bufferclass to avoid terrible accidents
  # This is compatible with R::Qt::Object, but associated C++ classes are NOT QObjects!
  class NoQtControl < Control

    public # methods of NoQtControl

      # overrides:
      def enqueue_children *args; end
      def qtobject?; end
      def widget?; end
      def qtparent_get; end
      def mark_ownership; end
      def qtchildren_get; []; end

      alias qtchildren qtchildren_get

      # override
      def qtparent= parent
	ArgError.raise "cannot assign a qtparent to a #{self.class}"
      end

      # override
      def qtchildren= arg
	ArgError.raise "cannot assign qtchildren to a #{self.class}"
      end

      # override. Because they are not QObjects in the first place
      def addObject child
	raise TypeError, "cannot add indiscrimate object (#{child}) to a #{self.class}"
      end # NoQtControl::addObject

      # called by attr.parent= self. Note that DynamicAttribute is a QObject. At least the baseclass is...
      def addDynamicAttribute attr
	#tag "#{self}::addDynamicAttribute(#{attr}) -> attr.takeOwnership"
	(@dynamic_attrs ||= []) << attr
	attr.takeOwnership
      end # NoQtControl::addDynamicAttribute

      def parent_get
	#tag "#{self}::parent_get @parent = #@parent"
        @parent
      end # NoQtControl::parent_get

      def objectName_get
        @objectName
      end # objectName_get

      # overrides
      attr_writer :objectName, :parent 

      # override
      def takeOwnership 
	NotImplementedError.raise 'takeOwnership on non-QObjects'
      end

  end  # class NoQtControl

  class SynthObject < R::Qt::Object
    # override
    def synthesized?; true; end
  end

end # module R::Qt

if __FILE__ == $0
  # controls can have dynamic arguments, these are Controls too.
  require_relative 'app'
  Reform::app {
  }
end
