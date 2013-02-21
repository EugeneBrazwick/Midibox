
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
	@instantiator = {}

	class << self

	  # returns class to use
	  def [] name; @instantiator[name]; end

	  def []= name, klass 
	    @instantiator[name.to_sym] = klass
	  end

	end # eigenclass Instantiator

      private # methods of Instantiator
      # It may return nil on exceptions... This is by design
      # Context: registerControlClassProxy(_i) <- Reform#internalize
      # The caller must test whether the method already exists.
	def define_proxy_method name, path
	  #tag "self=#{self}, name=#{name}, path=#{path}"
	  define_method name do |quicky = nil, &block|
	    R::escue do
	      # are we registered at this point?
	      # this is done by the require which executes createInstantiator.
	      unless Instantiator[name]
                #tag "arrived in #{self}##{name}, first time, loading file, just in time style"
		#tag "REQUIRE(#{path})"
		if path[0] == '/'
		  require path
		else
		  require_relative path
		end
		# the loaded module should call createInstantiator (and so registerControlClass) which alters
		# @@instantiator
		raise "'#{name}' did not register an instantiator!!!" unless Instantiator[name]
	      end
              #tag "HERE, name = #{name}"
	      klass = Instantiator[name]
	      unless quicky == nil || Hash === quicky
		ArgumentError.raise "Bad param #{quicky.inspect} passed to instantiator '#{name}'" 
	      end
#             tag "quicky hash = #{quicky.inspect}"
	      child = instantiate_child klass, self
	      child.setup quicky, &block
	    end # R::escue
	  end  # define_method
	  private name
	end # define_proxy_method

      public # methods of Instantiator

	# add a record to Instantiator.instantiator
	# context: Reform::createInstantiator
	def createInstantiator path, klass
	  Instantiator[path] = klass
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
	# if 'path' is a symbol we create an alias for name. This is done when
	# a softlink is read by internalize_dir
	#
	# Context: Reform::registerClassProxy
	def registerControlClassProxy name, path
	  name = name.to_sym
#          tag "#{self}::registerControlClassProxy_i(#{name}, #{realpath})"
	  # to avoid endless loops we must consider that by loading some classes it is possible
	  # that we already loaded the file:
	  return if private_method_defined? name
	  if method_defined? name
	    NameError.raise "the plugin #{self}.#{name} is already defined as " +
			    "#{instance_method(name).owner}.#{name}"
	  end
	  if Symbol === path
	    alias_method name, path
	    private name
	  else
	    define_proxy_method name, path
	  end
    # failing components do not stop the setup process.
	  #tag "Defining proxy_method #{self}.#{name}"  
	  # make it private to complete it:
	end # registerControlClassProxy_i

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

