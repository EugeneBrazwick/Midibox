
#STDERR.puts "loading liburqt.so"
require_relative 'liburqt'
require_relative 'control'

module R
  module Qt
    #forwards:
    class Model < Control; end
    class AbstractState < Control; end
    class AbstractAction < Control; end
    class Animation < Control; end
    class GraphicsItem < NoQtControl; end
    class Menu < Control; end
    class Widget < Control; end
  end # module Qt
end # module R

module Reform  # aka R::EForm

    ## basemodule for WidgetContext, GraphicContext etc.
    module Instantiator

	# hash Symbol=>class
	@@instantiator = {}

      private # methods of Instantiator
	# It may return nil on exceptions... This is by design
	def define_proxy_method name, thePath
	  #tag "define_proxy_method(#{name}, #{thePath})"
	  define_method name do |quicky = nil, &block|
	    R::escue do
	      # are we registered at this point?
	      # this is done by the require which executes createInstantiator.
	      unless @@instantiator[name]
                #tag "arrived in #{self}##{name}, first time, loading file, just in time style"
		require_relative thePath
		# the loaded module should call createInstantiator (and so registerControlClass) which alters
		# @@instantiator
		raise "'#{name}' did not register an instantiator!!!" unless @@instantiator[name]
	      end
              #tag "HERE, name = #{name}"
	      klass = @@instantiator[name]
	      unless quicky == nil || Hash === quicky
		raise ArgumentError, "Bad param #{quicky.inspect} passed to instantiator '#{name}'" 
	      end
#             tag "quicky hash = #{quicky.inspect}"
	      child = instantiate_child klass, self
	      child.setup quicky, &block
	    end # R::escue
	  end  # define_method
	end # define_proxy_method

      public # methods of Instantiator

	# add a record to @@instantiator
	def createInstantiator name, klass
	  @@instantiator[name.to_sym] = klass
	end # createInstantiator

	# Example:
	# ReForm::registerControlClassProxy 'mywidget' 'contrib_widgets/mywidget.rb'
	# It will create a 'mywidget' method. to which the name and setupblock
	# should be passed. So after this you can say
	#           mywidget {
	#              size 54, 123
	#           }
	# However, this is just a proxy.
	# The unit is NOT opened here. Only if this code is executed it will.
	# When called it performs 'require' and
	# the unit loaded should call registerControlClass and so createInstantiator above.
	# 
	# if 'thePath' is a symbol we create an alias for name. This is done when
	# a softlink is read by internalize_dir
	def registerControlClassProxy name, thePath
	  name = name.to_sym
#          tag "#{self}::registerControlClassProxy_i(#{name}, #{thePath})"
	  case thePath
	  when Symbol
#            tag "Create alias :#{name} :#{thePath}"
	    return module_eval("alias :#{name} :#{thePath}")
	  end
	  # to avoid endless loops we must consider that by loading some classes it is possible
	  # that we already loaded the file:
	  return if private_method_defined?(name)
    # failing components do not stop the setup process.
	  #tag "Defining proxy_method #{self}.#{name}"  
	  define_proxy_method name, thePath
	  # make it private to complete it:
	  private name
	end # registerControlClassProxy_i

	# return hash
	def self.instantiator
    #       tag "instantiator -> #{@@instantiator}"
	  @@instantiator
	end

	# returns class to use
	def self.[] name
	  @@instantiator[name]
	end
    end # module Instantiator

    # including this context makes all 'widgets' available as 'constructor' shortcuts.
    # Should be used for all classes that support Widget children.
    module WidgetContext
	extend Instantiator
    end # module WidgetContext

    # including this context makes all 'models' available as 'constructor' shortcuts
    module ModelContext
	extend Instantiator
    end # module ModelContext

    module GraphicContext
	extend Instantiator
    end # module GraphicContext

    module AnimationContext
	extend Instantiator
    end # module AnimationContext

=begin ????
    # include this to make it possible canning commands into named 'macros'.
    module MacroContext
	extend Instantiator

      private # methods of MacroContext

	#override
	def self.define_proxy_method name, thePath
	  define_method name do |quicky = nil, &block|
	    #tag "#{self.class}::#{name} called, creating Macro!"
	    Macro.new self, name, quicky, block
	  end # define_method
	end # define_proxy_method

    end # module MacroContext
=end

    module StateContext
	extend Instantiator
    end # module StateContext

      # for classes that can have 'menu' children
    module MenuContext
	extend Instantiator
    end # module MenuContext

      # for classes that can have 'action' children
    module ActionContext
	extend Instantiator
    end # module ActionContext

    # this tells us which controls are added where.
    # But a class can then 'include' the contexts to use.
    Contexts = { R::Qt::Widget=>[WidgetContext], 
		 R::Qt::Model=>[ModelContext],
		 R::Qt::Object=>[ModelContext],
		 R::Qt::GraphicsItem=>[GraphicContext],
		 R::Qt::Animation=>[AnimationContext],
		 R::Qt::AbstractState=>[StateContext],
		 R::Qt::Menu=>[MenuContext],
		 R::Qt::AbstractAction=>[ActionContext],
		 R::Qt::Control=>[WidgetContext, ModelContext, GraphicContext,
				  AnimationContext, StateContext, MenuContext,
				  ActionContext] # aka 'any'
		}

    def self.context4 klass
  #     tag "getContext4(#{klass})"
      Contexts[klass] || context4(klass.superclass)
    end # self.context4

  public  # methods of Reform

    def self.createInstantiator file, klass
      name = File.basename file, '.rb'
      for context in context4(klass)
	context.createInstantiator name, klass
      end
    end # self.createInstantiator
end # module Reform

