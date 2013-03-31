
#  Copyright (c) 2013 Eugene Brazwick

require_relative 'core_app'
require_relative 'context'
require_relative 'liburqt'

module Reform

  private # methods of EForm

  # scan given dir for fixed set of subdirectories. Each maps to a context by hash.
  # +hash+ is a mapping from dir to klass. The klass is passed
  # to registerClassProxy and should be the key inside the Contexts array.
  #
  # each file not starting with '_' is supposed to be a pluging and it
  # added as a method to the proper context.
  # symlinks will cause 'alias' to be used.
  #
  # known problem: 
  # the plugin-method (like 'widget') will first do a require_relative.
  #
    def self.internalize dirprefix, hash
#       tag "internalize"
      # note that dirs need not exist. But at least one should!
      located_any_plugins = false
      for dir, klass in hash
	fulldir = if dirprefix.empty? then dir.to_s else "#{dirprefix}/#{dir}" end
	unless fulldir[0] == '/'
	  fulldir = File.dirname(__FILE__) + '/' + fulldir
	end
	symlinks = {}
        #tag "GLOBBING #{fulldir}/*.rb"
	for file in Dir["#{fulldir}/*.rb", "#{fulldir}/*.so"]
	  #tag "file = '#{file}'"
	  basename = File.basename(file).sub(/\.rb$|\.so$/, '')
	  next if basename[0] == '_'
          #tag "INTERNALIZE #{basename} from #{file}"
	  if File.symlink?(file)
	    link_basename = File.basename(File.readlink(file)).sub(/\.rb$|\.so$/, '')
	    next if link_basename[0] == '_'
	    symlinks[basename.to_sym] = link_basename.to_sym
	  else
	    #tag "registerClassProxy(#{klass}, #{basename})"
	    registerClassProxy klass, basename, "#{dirprefix}/#{dir}/#{basename}"
	  end
	  located_any_plugins = true
	end # for
	symlinks.each { |key, value| registerClassProxy klass, key, value }
      end # for
      unless located_any_plugins
	Reform::Error.raise "incorrect plugin directory '#{dirprefix}'"
      end
    end

    # scan given dirs for fixed set of subdirectories. Each maps to a context
    def self.internalize_dir *dirs
#       tag "internalize_dir #{dirs.inspect}"
      for dir in dirs
#         tag "Calling internalize #{dir}"
	internalize dir, widgets: R::Qt::Widget, graphics: R::Qt::GraphicsItem,
			 models: R::Qt::Model, any: R::Qt::Control,
			 animations: R::Qt::AbstractAnimation
      end
    end # internalize_dir

  public # methods of R::EForm

    # create a Qt application, read the plugins, execute the block
    # in the context of the Qt::Application 
    def self.app quickyhash = nil, &block
      app_i R::Qt::Application, quickyhash, &block
    end # app

    # delegator. see Instantiator::registerControlClassProxy
    #  we add the X classProxy to those contexts in which we want the plugins
    # to become available.
    #
    # Context: internalize
    def self.registerClassProxy klass, id, path
      contexts = Contexts[klass] and
	contexts.each { |ctxt| ctxt::registerControlClassProxy id, path }
    end # self.registerClassProxy

end # module Reform

module R::Qt

  @@alignmentflags = nil

  class Application < CoreApplication
    include Reform::ModelContext, Reform::WidgetContext,
	    Reform::GraphicContext

    private # methods of Application

      def initialize 
	super
	@toplevel_widgets = []
	@autostart_anims = true
      end

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

      def fail_on_errors value
	@fail_on_errors = value
      end

      def autostart_anims value
	@autostart_anims = value
      end

      alias failOnErrors fail_on_errors

    public # methods of Application

      # override
      def enqueue_children queue = nil
	super
	@toplevel_widgets.each { |wdgt| queue and queue.push wdgt or yield wdgt }
      end

      def load_plugins?; true; end

      # you cannot say:    attr :fail_on_errors?
      def fail_on_errors?; @fail_on_errors; end
      def autostart_anims?; @autostart_anims; end

      # override, kind of
      def addWidget widget
	@toplevel_widgets << widget
	#tag  "#{widget}.@parent := self"
	widget.instance_variable_set :@parent, self
      end # addWidget

      ## setup + Qt eventloop start
      def execute
	super if setupForms 
      end #  execute

      ## delete the toplevel widgets and the global $app variable
      def cleanup
	# tag "Application::cleanup, #toplevel_widgets = #{@toplevel_widgets.length}"
	@toplevel_widgets.each(&:delete)
	super
      end
  end # class Application
end # module R::Qt

if __FILE__ == $0
  Reform.app {
    $stderr.puts "END OF APP"
  }
  $stderr.puts "CLEANED UP OK!"
end
