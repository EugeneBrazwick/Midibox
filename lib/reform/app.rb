
#  Copyright (c) 2013 Eugene Brazwick

require_relative '../urqt/liburqt'
require_relative 'control'
require_relative 'context'

module R

  public # methods of R
    # use this to wrap a rescue clause around any block.
    # transforms the exception (RuntimeError+IOError+StandardError) to a warning on stderr.
    def self.escue
      begin
        return yield
      rescue IOError => exception
        msg = "#{exception.message}\n"
      rescue Reform::Error => exception
	raise if $app.fail_on_instantiation_errors?
        msg = "#{exception.class}: #{exception}\n" + exception.backtrace.join("\n")
      rescue StandardError, RuntimeError => exception
	#tag "got exception"
	#tag "exception class: #{exception.class}"
	#tag "exception msg: #{exception}"
	#tag "exception backtrace: #{exception.backtrace.join "\n"}"
        msg = "#{exception.class}: #{exception}\n" + exception.backtrace.join("\n")
      end
      $stderr << msg
    end # escue

end # module R

module Reform

  private # methods of EForm

    # scan given dir for fixed set of subdirectories. Each maps to a context by hash
    def self.internalize dirprefix, hash
#       tag "internalize"
      dirprefix = File.dirname(__FILE__) + '/' + dirprefix unless dirprefix[0] == '/'
      # note that dirs need not exist. But at least one should!
      located = false
      for dir, klass in hash
	fulldir = dirprefix + '/' + dir.to_s
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
      raise Reform::Error, tr("incorrect plugin directory '#{dirprefix}'") unless located
    end

    # scan given dirs for fixed set of subdirectories. Each maps to a context
    def self.internalize_dir *dirs
#       tag "internalize_dir #{dirs.inspect}"
      for dir in dirs
#         tag "Calling internalize #{dir}"
	internalize dir, widgets: R::Qt::Widget, graphics: R::Qt::GraphicsItem,
			 models: R::Qt::Model
      end
    end # internalize_dir

  public # methods of R::EForm

    # create a Qt application, read the plugins, execute the block
    # in the context of the Qt::Application 
    def self.app &block
      R::Qt::Application.new.scope do |app|
	begin
	  # note that app is identical to $app
	  internalize_dir '.', 'contrib'
	  app.instance_eval &block if block	
	  app.execute
	ensure
	  app.cleanup
	end
      end # scope
    end # app

    # delegator. see Instantiator::registerControlClassProxy
    #  we add the X classProxy to those contexts in which we want the plugins
    # to become available.
    def self.registerClassProxy klass, id, path = nil
      contexts = Contexts[klass] and
	contexts.each { |ctxt| ctxt::registerControlClassProxy id, path }
    end # self.registerClassProxy

end # module R::EForm

module R::Qt

    class Application < Control
      include Reform::ModelContext, Reform::WidgetContext,
	      Reform::GraphicContext

      private # methods of Application

	# run (show) first widget defined.
        # if a model is set, propagate it
	# It is bad to do nothing, if there is no widget available (shown)
        # then Qt will just hang about.
        # returns toplevel widget.
	def setupForms
	  #tag "setupForms, children=#{children}"
	  top = @toplevel_widgets[0] and top.show
	  #tag "located top: #{top}"
	  top
	end # setupForms
 
	def fail_on_instantiation_errors value
	  @fail_on_instantiation_errors = value
	end

      protected # methods of Application

	# override
	def each_extrachild
	  #tag "each_extrachild, toplevel_widgets=#@toplevel_widgets"
	  @toplevel_widgets.each { |tlw| yield tlw }
	end

      public # methods of Application

	def fail_on_instantiation_errors?
	  @fail_on_instantiation_errors
	end

	# override
	def children_get
	  super + @toplevel_widgets
	end # children_get

	alias :children :children_get

	# override, kind of
	def addWidget widget
	  @toplevel_widgets << widget
	  #tag  "#{widget}.@parent := self"
	  widget.instance_variable_set :@parent, self
	end # addWidget

	## setup + Qt eventloop start
	def execute
	  setupForms and exec
	end #  execute

	## delete the toplevel widgets and the global $app variable
	def cleanup
	  #tag "Application::cleanup, #toplevel_widgets = #{@toplevel_widgets.length}"
	  @toplevel_widgets.each &:delete 
	  $app = nil
	end
    end # class Application
end # module R::Qt

if __FILE__ == $0
  Reform.app {
    $stderr.puts "END OF APP"
  }
  $stderr.puts "CLEANED UP OK!"
end
