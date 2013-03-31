
# This document adheres to the GNU coding standard as much as possible
#  Copyright (c) 2013 Eugene Brazwick

require_relative 'control'
require_relative 'context'

module R::Qt

=begin :rdoc:

  a DynamicAttribute makes it possible to split a value into components, each of which
  can be a plain value (of some type) but also another DynamicAttribute.

    Examples:

	  pen widthF: 3.0				# not dynamic
	  pen {
	    widthF connector: :pensz			# dynamic
	  }

	  fill color: 'DodgerBlue3'			# not dynamic
	  fill {
	    color connector: :fillcolor			# dynamic
	  }
	  fill {
	    color {					# uber-dynamic 
	      red 254					# not dynamic
	      blue connector: [:fillcolor, :blue]	# dynamic
	      green connector: -> data { data.green }	# dynamic, readonly
	    } # color
	  } # fill

  The whole system works through message passing and delegation.
=end
  class DynamicAttribute < Control
      include Reform::AnimationContext

    private # methods of DynamicAttribute

      def default_value
	#tag "#{self}, calculating default for #@klass::#@methodname"
	if @klass.respond_to?(:new)
	  @klass.new
	else
	  case	  # cannot use @klass  !!
	  when @klass == Fixnum then 0
	    # Note that String has 'new'
	  when @klass == Float then 0.0
	  when @klass == TrueClass then true 
	  when @klass == FalseClass then false 
	  when @klass == NilClass then nil 
	  when @klass == Integer then 0
	  else
	    raise Reform::Error, "Klass #@klass has no default provided"
	  end
	end
      end

    ## - parent is the owner, can be any control, does not need to be a QObject.
    #  - klass is the type of the value, this is required for Qt typeing. 
    #	 You can use ruby classes like Fixnum, Float or String etc  
    #	 The type also decides the default. Using FalseClass results in false being
    #	 the default, while TrueClass uses true instead. Otherwise it is the 'zero' of
    #	 the type.
    #  - methodname. Name of the attribute, like 'color', 'red', or 'widthF'
    #  - options. Specific options for subclasses. Possible values:
    #	    - klass. DynamicAttribute (sub)class to instantiate, the default is DynamicAttribute.
    #  - quickyhash. As specified by the user. 
    #  - initblock. As specified by the user.
      def initialize parent, klass, methodname, options, quickyhash = nil, &initblock
	#tag "DynamicAttribute.new(#{parent}, #{klass}, :#{methodname}), options=#{options}"
	super(parent) {}    # strange, but ruby WILL pass the initblock otherwise
	@klass, @methodname, @options = klass, methodname, options
	#tag "new #{self}::#{methodname}, assign da_value, using default_value"
	self.da_value = default_value  # this must come first
	#tag "#{self}:#{methodname}.setup(#{quickyhash.inspect})"
	setup quickyhash, &initblock
	#tag "#{self}.@connector = #{connector.inspect}"
	connector and parent.connect_attribute @methodname, self
      end

      def da_value= v
	#tag "#{self}::setProperty(#{DynValProp}, #{v.inspect})"
	setProperty DynValProp, v
	#tag "property is now #{property(DynValProp).inspect}"
      end

      def da_value
	#tag "#{self} da_value() returning property[#{DynValProp}] -> #{property(DynValProp)}"
	property DynValProp
      end

    protected # methods of DynamicAttribute

    public # methods of DynamicAttribute

      # override
      def parent= parent
	#tag "#{self}.parent = #{parent}, parent.qtobject? = #{parent.qtobject?}"
	if parent.qtobject?
	  self.qtparent = parent
	else
	  @parent = parent
	end
	#	raise "er ohhhh AARGHH??" unless self.parent == parent
	parent.addDynamicAttribute self
      end # parent=

      def apply_model data
	#tag "#{self}::apply_model -> delegate to #{parent.class}::apply_dynamic_setter(#@methodname)"
	#tag "data = #{data}"
	parent.apply_dynamic_setter @methodname, data
      end # apply_model

      # override
      def apply_dynamic_getter method
	#tag "apply_dynamic_getter :#{method}"
	#tag "#{da_value}.#{method}_get()"
	# 	tag "da_value = #{da_value.inspect}"	  STACK OVERFLOW ??
        da_value.send method.to_s + '_get'
      end # apply_dynamic_getter

      # override
      def apply_dynamic_setter method, *args
	#tag "#{self}::apply_dynamic_setter :#{method}(#{args.inspect}), first get the current value"
        propval = da_value
	#ag "#retrieved value #{propval.inspect}" 
        propval.send method.to_s + '=', *args
        #setProperty DynValProp, value2variant propval
        parent.send @methodname.to_s + '=', propval
      end # apply_dynamic_setter

      # PROBLEMATIC: the old code always caught DynamicPropertyChangeEvent.
      # But now we would have to create a ObjectEventBroker on each DynamicAttribute.
      # That would be bad.
      # It is now done by PropertyAnimation.startValue=, but that has to erase
      # all handlers on dynamicPropertyChanged. 
      # And 'disconnect' is NIY!
  end # class DynamicAttribute
end # module R::Qt
