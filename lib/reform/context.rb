
module R
  module Qt
    #forwards:
    class AbstractModel < Control; end
    class AbstractState < Control; end
    class AbstractAction < Control; end
    class Animation < Control; end
    class GraphicsItem < Control; end
    class Menu < Control; end
    class Widget < Control; end
  end # module Qt
end # module R

module Reform  # aka R::EForm

=begin :rdoc:
    basemodule for WidgetContext, GraphicContext etc.
    As such it has a big impact on all Frame and Scene derivates, 
    which are most container classes.

    For example: including GraphicContext means that you get access to methods like
    'circle', 'rect' etc.  But these are ALL plugins from the corresponding directory.
    In this case reform/graphics. By storing the methods inside the contect
    we automatically
    make them available precisely (pinpoint accuracy!) to the classes of our choice.
    A class can easily support more than one context.

    First we have instantiators for each file/class in the controls or graphics directory.
    For example, since canvas.rb is in controls/ we have an instantiator 'canvas' in all
    frames (widgetcontainers) and its subclasses.
    This instantiator accepts an optional string and a setup block.
    When called we decide to what parent to add the control, associated with the class involved,
    in this case a 'Canvas', which is a Qt::GraphicsView wrapper (see canvas.rb).
    At that point first the Qt implementor is instatiated, and then the Reform wrapper.
    We then call Canvas.addControl(graphicsview, setupblock).
    This should execute the setupblock, and finally call postSetup on the canvas.
=end
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
	      # It's important to use parent_qtc_to_use, since it must be a true widget.
	      parent = quicky && quicky[:parent] || parent2use4(klass)
	      child = instantiate_child klass, parent
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

    Contexts = { R::Qt::Widget=>[WidgetContext], # , MacroContext],
		 R::Qt::AbstractModel=>[ModelContext],
		 R::Qt::Object=>[ModelContext],
		 R::Qt::GraphicsItem=>[GraphicContext], # , MacroContext],
		 R::Qt::Animation=>[AnimationContext], # , MacroContext],
		 R::Qt::AbstractState=>[StateContext], # , MacroContext],
		 R::Qt::Menu=>[MenuContext],
		 R::Qt::AbstractAction=>[ActionContext]
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

