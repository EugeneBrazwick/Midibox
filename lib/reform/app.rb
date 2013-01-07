
require_relative '../urqt/liburqt' 
require_relative 'object'

module R
    module EForm; end

  public # methods of R
    # use this to wrap a rescue clause around any block.
    # transforms the exception (RuntimeError+IOError+StandardError) to a warning on stderr.
    def self.escue
      begin
        return yield
      rescue IOError => exception
        msg = "#{exception.message}\n"
      rescue StandardError, RuntimeError => exception
        msg = "#{exception.class}: #{exception}\n" + exception.backtrace.join("\n")
      end
      $stderr << msg
    end # escue
end # module R

module R::EForm

    class Error < StandardError
    end # class Error

=begin :rdoc:
    basemodule for ControlContext, GraphicContext etc.
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
	  define_method name do |quicky = nil, &block|
	    R::escue do
	      # are we registered at this point?
	      # this is done by the require which executes createInstantiator.
	      unless @@instantiator[name]
                tag "arrived in #{self}##{name}, first time, loading file, just in time style"
		require_relative thePath
		# the loaded module should call createInstantiator (and so registerControlClass) which alters
		# @@instantiator
		raise "'#{name}' did not register an instantiator!!!" unless @@instantiator[name]
	      end
              tag "HERE, name = #{name}"
	      klass = @@instantiator[name]
	      unless quicky == nil || Hash === quicky
		raise ArgumentError, "Bad param #{quicky.inspect} passed to instantiator '#{name}'" 
	      end
  #             tag "quicky hash = #{quicky.inspect}"
	      # It's important to use parent_qtc_to_use, since it must be a true widget.
	      parent = quicky && quicky[:parent] || parent2use4(klass)
	      instantiate_child klass, parent
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
	  #tag "Defining method #{self}.#{name}"  
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
    module ControlContext
	extend Instantiator
    end # module ControlContext

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
	    tag "#{self.class}::#{name} called, creating Macro!"
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

    #forwards:
    class Control < R::Qt::Object; end
    class AbstractModel < Control; end
    class AbstractState < Control; end
    class AbstractAction < Control; end
    class Animation < Control; end
    class GraphicsItem < Control; end
    class Menu < Control; end
    class Widget < Control; end

    Contexts = { Widget=>[ControlContext], # , MacroContext],
		 AbstractModel=>[ModelContext],
		 R::Qt::Object=>[ModelContext],
		 GraphicsItem=>[GraphicContext], # , MacroContext],
		 Animation=>[AnimationContext], # , MacroContext],
		 AbstractState=>[StateContext], # , MacroContext],
		 Menu=>[MenuContext],
		 AbstractAction=>[ActionContext]
		}

  private # methods of EForm

    # scan given dir for fixed set of subdirectories. Each maps to a context by hash
    def self.internalize dirprefix, hash
#       tag "internalize"
      dirprefix = File.dirname(__FILE__) + '/' + dirprefix unless dirprefix[0] == '/'
      # note that dirs need not exist. But at least one should!
      located = false
      for dir, klass in hash
	fulldir = dirprefix + '/' + dir
	symlinks = {}
#         tag "GLOBBING #{dirprefix}/#{dir}/*.rb"
	for file in Dir["#{fulldir}/*.rb"]
	  basename = File.basename(file, '.rb')
#          tag "INTERNALIZE #{basename} from #{file}"
	  if File.symlink?(file)
	    symlinks[basename.to_sym] = File.basename(File.readlink(file), '.rb').to_sym
	  else
	    registerClassProxy klass, basename, "#{dirprefix}/#{dir}/#{basename}"
	  end
	  located = true
	end # for
	symlinks.each { |key, value| registerClassProxy klass, key, value }
      end # for
      raise Error, tr("incorrect plugin directory '#{dirprefix}'") unless located
    end

    # scan given dirs for fixed set of subdirectories. Each maps to a context
    def self.internalize_dir *dirs
#       tag "internalize_dir #{dirs.inspect}"
      for dir in dirs
#         tag "Calling internalize #{dir}"
	internalize dir, 'widgets'=>Widget
      end
    end # internalize_dir

    def self.context4 klass
  #     tag "getContext4(#{klass})"
      Contexts[klass] || context4(klass.superclass)
    end

  public # methods of R::EForm
    # create a Qt application, read the plugins, execute the block
    # in the context of the Qt::Application 
    def self.app &block
      app = R::Qt::Application.new
ObjectSpace::define_finalizer(app, -> id { puts "DEBUG: Finalizing Application #{id}" })  # FIXME
      # note that app is identical to $qApp
      internalize_dir '.' # FIXME , 'contrib'
      block and app.instance_eval(&block)
      app.execute
    ensure
      app.whenExiting
    end # app

    # delegator. see Instantiator::registerControlClassProxy
    #  we add the X classProxy to those contexts in which we want the plugins
    # to become available.
    def self.registerClassProxy klass, id, path = nil
      contexts = Contexts[klass] and
	contexts.each { |ctxt| ctxt::registerControlClassProxy id, path }
    end

    def self.createInstantiator file, klass
      name = File.basename file, '.rb'
      for context in context4(klass)
	context.createInstantiator name, klass
      end
    end
end # module R::EForm

Reform = R::EForm

module R::Qt

    class Object  # ie Qt::Object
      public # methods of Object
    end # class Object

    class Control < Object  # ie Qt::Object!
      private  # methods of Control
	# callback
	def parent2use4 child
	  self
	end	  

        def instantiate_child klass, parent
	  tag "#{klass}.new(#{parent})"
          c = klass.new parent
ObjectSpace::define_finalizer(c, -> id { puts "Finalizing #{klass} #{id}" })  # FIXME
	  c
        end
    end # class Control

    class Application < Control
      include Reform::ModelContext, Reform::ControlContext,
	      Reform::GraphicContext

      private # methods of Application
	# run (show) first widget defined.
        # if a model is set, propagate it
	# It is bad to do nothing, if there is no widget available (shown)
        # then Qt will just hang about.
        # returns toplevel widget if show works
	def setupForms
	  findChild(&:widget?).show
	end # setupForms
   
      public # methods of Application
  
	# User can set this callback. Called by 'app'
	def whenExiting &callback
	  if callback
	    @whenExiting = callback
	  else
	    @whenExiting[] if @whenExiting
	  end
	end # whenExiting

	# setup + Qt eventloop start
	def execute
	  setupForms and exec
	end #  execute
    end # class Application
end # module R::Qt

if File.basename($0) == 'rspec'
  include R::EForm
  describe "R::EForm" do
    R::EForm.app {
    } # app
  end
end

