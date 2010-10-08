#
# Copyright (c) 2010 Eugene Brazwick

verb, $VERBOSE = $VERBOSE, false
require 'Qt'
$VERBOSE = verb

# for debugging purposes only
# if $DEBUG
module Kernel

  private
    def tag msg
      # avoid puts for threading problems
      STDERR.print "#{File.basename(caller[0])} #{msg}\n"
    end

    def trace onoff = true
      if onoff
        set_trace_func -> event, file, line, id, binding, classname do
          printf "%8s %s:%-2d %-15s %-15s\n", event, file, line, classname, id
        end
        if block_given?
          begin
            yield
          ensure
            set_trace_func nil
          end
        end
      else
        set_trace_func nil
      end
    end

    # this is the ugly way to make 'with' in ruby. CURRENT STATE: unused
    # also this will not work 'with x do attrib = 3'
    def with arg, &block
      arg.instance_eval(&block)
    end

    # use this to wrap a rescue clause around any block.
    # transforms the exception (RuntimeError+IOError+StandardError) to a warning on stderr.
    def rfRescue
      begin
        return yield
  #       rescue LocalJumpError
        # ignore
      rescue IOError, RuntimeError => exception
        msg = "#{exception.message}\n"
      rescue StandardError => exception
        msg = "#{exception.class}: #{exception}\n" + exception.backtrace.join("\n")
      end
      # this must be fixed using an alert, but it may depend on the kind of exception...
      $stderr << msg
    end

end

class Fixnum
  # create an instance of Reform::Milliseconds
  def seconds
    Reform::Milliseconds.new(self * 1000)
  end

  alias :s :seconds

  # create an instance of Reform::Milliseconds
  def milliseconds
    Reform::Milliseconds.new(self)
  end

  alias :ms :milliseconds

end

class Numeric
  public
    # where lower < upper.  The result is always between these.
    #  7.clamp(3, 5) -> 5
    #  7.clamp(9, 14) -> 9
    #  7.clamp(3, 14) -> 7
    def clamp lower, upper
      self < lower ? lower : self > upper ? upper : self
    end
end

# The Reform library is a qtruby based library for building gui's in a 100%
# declarative way (we do not compromise!!!)
# There are NO methods involved. Ever. Anywhere.
#
# Required deb packages (for Ubuntu):
# - rubygems1.9.1
# - cmake
# - g++
# - qt4-qmake
# - ruby1.9.1-dev
# - libqt4-dev
# - libasound2-dev
#
# Required gems:
# - qtbindings
# - rspec
#
# Optional gems:
# - darkfish-rdoc
#
# CONCEPTS
# ========================================
#
# Shoes (as in 'stolen from')
#
# But 'shoes' is too much a toy.
#
# The idea is to map a datastructure one-on-one on a form. By picking the controls
# you can make any view for a model.
#
# Richard Dale has made two qtruby modelsystems that can be used for ActiveRecord and
# ActiveResource.
# I would like to add one for Object. Or even BasicObject. Because any ruby instance is
# obviously a model.
#
# A program looks like this:
#
#    Reform::app {
#      formX {
#        widgetA {
#          prop1 value1
#          .....
#        }
#        widgetB {
#          properties for widgetB
#        }
#        ....
#      } #
#      formY {
#         ....
#      }
#    }
#
# The syntax is the same on each and every level.
# All available widgets (and other stuff) are plugins stored in one of the
# lib/reform subdirectories. We have:
# [controls] for widgets and layouts
# [graphics] for graphic items
# [states] for states
# [models] for models
#
# etc..
# The names of the files are the names of the possible 'constructors' in +Reform::app+.
#
module Reform

    # A class specifically representing a duration in milliseconds
    # See Fixnum#seconds and Fixnum#milliseconds
    class Milliseconds
      private
        def initialize val
          @val = val
        end
      public
        attr :val
        alias :value :val # required for Qt::Variant interaction etc/
    end

    MilliSeconds = Milliseconds


    # Use this class for GUI errors, including misconfigurations.
    class Error < StandardError
    end

    ReformError = Error

=begin
    baseclass for ControlContext, GraphicContext etc.
    As such it has a big impact on all Frame and Scene derivates, which are most container classes.

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

    #     tag "@@instantiator := {}"
        @@instantiator = {}

      public

        def createInstantiator_i name, qt_implementor_class, reform_class, options = nil
          @@instantiator[name.to_sym] = { qt_implementor_class: qt_implementor_class, reform_class: reform_class,
                                          options: options }
        end # createInstantiator_i

        # Example:
        # ReForm::registerControlClassProxy 'mywidget' 'contrib_widgets/mywidget.rb'
        # It will create a 'mywidget' method. to which the name and setupblock
        # should be passed. So after this you can say
        #           mywidget {
        #              size 54, 123
        #           }
        # However, this is just a proxy.
        # The unit is NOT opened here. Only if this code is executed will it.
        # When called it performs 'require' and
        # the unit loaded should call registerControlClass and so createInstantiator_i above
        # It used to overwrite the 'name' method, but calling remove_method name from within 'name'
        # itself caused sporadic SEGV's....
        # And it was overly complicated as well.
        # For internal use only (hence _i suffix)
        def registerControlClassProxy_i name, thePath
          name = name.to_sym
    #       tag "#{self}::registerControlClassProxy_i(#{name}, #{thePath})"
          # to avoid endless loops we must consider that by loading some classes it is possible
          # that we already loaded the file.
          if Symbol === thePath
    #         tag "Create alias :#{name} :#{thePath}"
            module_eval("alias :#{name} :#{thePath}")
            return
          end
          return if private_method_defined?(name)
  #         tag "Defining method #{self}.#{name}"  # It may return nil on exceptions... THis is by design
    # failing components do not stop the setup process.
          define_method name do |quicky = nil, &block|
            c = nil
            rfRescue do
              # are we registered at this point?
              # this is done by the require which executes createInstantiator_i.
              # IMPORTANT ruby1.9.2 corrupts name2 somehow.  Using name3 does the trick however
              unless @@instantiator[name]
      #           tag "arrived in #{self}##{name}"
                require_relative thePath
                # the loaded module should call createInstantiator (and so registerControlClass) which alters
                # @@instantiator
                raise "'#{name}' did not register an instantiator!!!" unless @@instantiator[name]
              end
              instantiator = @@instantiator[name]
              reform_class = instantiator[:reform_class]
              options = instantiator[:options]
              qt_implementor_class = instantiator[:qt_implementor_class]
              raise ArgumentError, 'Bad hash passed to instantiator' unless quicky == nil || Hash === quicky
  #             tag "quicky hash = #{quicky.inspect}"
              # It's important to use parent_qtc_to_use, since it must be a true widget.
              # Normally, 'qparent' would be '@qtc' itself
              qparent = quicky && quicky[:qtparent] || parent_qtc_to_use_for(reform_class)
=begin
          Severe problem:     sometimes the parenting must change but how can this be done before
                              even the instance exists?
          Example: creating a Qt::Layout with parent Qt::MainWindow will fail!
          Answer: HACK IT!
=end
              ctrl = self
    #         graphicsproxy = false
      # the smoke hacks prevent this from working since internally Qt::VBoxLayout subclasses Qt::Base !!!
    # Oh my GOD!!
    # NOT GOING TO WORK.
    #  BAD respond_to is USELESS!!        if qparent.respond_to?(:layout) && qparent.layout && reform_class <= Layout  # smart!!
=begin
                # assuming that qt_implementor_class <= QLayout, and layout is
                # constructed with parent == 0 (see for example widgets/calendar/window.cpp )
                #             && #(qparent.widgetType? && qparent.layout ||
                # insert an additional generic frame (say Qt::GroupBox)
    #     you cannot store a QWidget in a g-scene but since it accepts QGraphicsItems it is possible to
    #     create a QGraphicsProxyWidget

    # we create the implementor first, then the wrapper
    #         tag "reform_class=#{reform_class}, calling new_qt_implementor for #{qt_implementor_class}, parent=#{qparent}"
=end
    #         raise 'CANTHAPPEN' if qparent && qparent.inherits('QGraphicsScene')
    #         tag "instantiate #{qt_implementor_class} with parent #{ctrl}/#{qparent}"
              newqtc = qt_implementor_class &&
                      ctrl.instantiate_child(reform_class, qt_implementor_class, qparent)
      #         tag "#{reform_class}.new(#{ctrl}, #{newqtc})"
              c2 = reform_class.new ctrl, newqtc
      #           tag "instantiated c=#{c}, parent is a #{ctrl.class}"
                # add will execute block, and then also call postSetup
      #           tag "CALLING #{ctrl}.add(#{c})"
              ctrl.add(c2, quicky, &block)
              c = c2
            end
    #         tag "IMPORTANT: method '#{name}' return the control #{c}"
            c
          end  # define_method

          # make it private to complete it:
          private name

        end # registerControlClassProxy_i

        def self.instantiator
    #       tag "instantiator -> #{@@instantiator}"
          @@instantiator
        end

        def self.[] name
          @@instantiator[name]
        end
    end # module Instantiator

    # ControlContext means we get the instantiators in the 'controls' directory.
    # So things including ControlContext can contain other widgets
    module WidgetContext
      extend Instantiator
    end

    ControlContext = WidgetContext

    # GraphicContext means we get the instantiators in the 'graphics' directory.
    module GraphicContext
      extend Instantiator
    end # module GraphicContext

    # ModelContext means we can create models for the control that includes it
    # These are all in the 'models' subdirectory
    module ModelContext
      extend Instantiator

      private

        # shortcut. You can then say simple_data 'hallo', 'world'
        def simple_data *val
          ruby_model value: if val.length == 1 then val[0] else val end
        end

        alias :simpledata :simple_data

        def simplestruct *val
          structure value: if val.length == 1 then val[0] else val end
        end

    end # module ModelContext

    # MenuContext means we can create menus for the control that includes it
    # These are all in the 'menus' subdirectory
    module MenuContext
      extend Instantiator
    end

    # ActionContext means we can create actions for the control that includes it
    # These are all in the 'actions' subdirectory
    module ActionContext
      extend Instantiator
      private
        # add given action symbols to the menu
        def actions *list
          list = list[0] if list.length == 1 && Array === list[0]
          frm = containing_form
          list.each do |action|
  #           tag "Add action #{action.inspect}"
            add(frm.action(action), nil)
          end
        end
    end

    module AnimationContext
      extend Instantiator
    end

    module StateContext
      extend Instantiator
    end

    # this class just stores a name with the arguments to a widget constructor
    class Macro
      private
        def initialize control, name, quicky, block
    #       tag "Macro.new(#{control}, #{name})"
          @control, @name, @quicky, @block = control, name, quicky, block
          # WTF??? macros have not a name perse, so macros[name] = self DESTROYS macros!!!!
          control.macros! << self if control
        end
      public
        def exec receiver = nil
    #       tag "executing macro #{@control.class}::#@name, args=#@quicky, block=#@block"
          (receiver ||= @control).send(@name, @quicky, &@block) #.tap do |t|
    #         tag "macroresult is #{t}"
    #       end
        end
    #         attr :quickylabel, :block
        attr_accessor :name

        def to_s
          "#{@control.class}::#@name(#{@quicky}) BLOCK #{@block.inspect}"
        end
    end # class Macro
  #

    # experimental. 'Cans' graphicitem setups
    module SceneFrameMacroContext
    #     def self.createInstantiator_i name
        def self.createInstantiator_i name, qt_implementor_class, reform_class, options = nil
        end

        def self.registerControlClassProxy_i name, thePath
          name = name.to_sym
          return if private_method_defined?(name)
          define_method name do |quicky = nil, &block|
            Macro.new(self, name, quicky, block)
          end
          private name
        end

    end # module SceneFrameMacroContext

    module AppMacroContext
=begin
    registerControlClassProxy_i(string name, string relativepath)
    create a method 'theName' within the caller class, the implementor
    must be located in the file with the designated path (which must be relative).
    If the method already exists, this is silenty ignored and nothing is done.
    The method will have an optional argument 'label', and a block for initialization.
    It basically delegates to the application, using send.

    Use through Reform::registerControlClassProxy
=end
        def self.registerControlClassProxy_i name, thePath
          name = name.to_sym
          if Symbol === thePath
    #         tag "Create alias :#{name} :#{thePath}"
            module_eval "alias :#{name} :#{thePath}"                # 'alias' is an UTTER HACK!
            return
          end
    #       tag "registerControlClassProxy_i(#{name}, #{thePath})"
          return if private_method_defined?(name)
    #       tag "define_method #{self}::#{name}"
          define_method name do |quicky = nil, &block|
    #         tag "executing ControlClassProxy app##{name}"
            unless Instantiator[name]
              require_relative thePath
              raise "'#{name}' did not register an instantiator!!!" unless Instantiator[name]
            end
            instantiator = Instantiator[name]
            reform_class = instantiator[:reform_class]
            options = instantiator[:options]
            qt_implementor_class = instantiator[:qt_implementor_class]
            if options[:form]
              qform = qt_implementor_class.new
    #           tag "app.#{name}, calling #{reform_class}.new to get a form"
              form = reform_class.new qform
    #           tag "instantiated #{form}"
              @firstform ||= form   # it looks the same, but is completely different
    #           tag "Assigning setup"
              form.setup = quicky ? quicky : block
    #           tag "and now we wait for 'run'"
              form
            elsif @autoform
              raise ReformError, 'put controls in forms' unless @all_forms.length <= 1
              # it seems that 'form' is not the instantiator here??
    #           tag "form=#{form.inspect}"  -> NIL
    #             tag "Instantiating autoform '#@autoform', unless #@firstform"
              @firstform ||= send(@autoform)
              # we delay creating the elements until form.run is called.
              Macro.new(@firstform, name, quicky, block)
    #           tag "create macro in #@firstform for #{name}, macrocount is now #{@firstform.macros.length}"
            else
              # is this a proper constraint?
              raise ReformError, 'only 1 control can be on top' if @firstform
              qctrl = qt_implementor_class.new
    #           tag "reform_class=#{reform_class}, qctrl=#{qctrl}"
              @firstform = reform_class.new(nil, qctrl)
            end
          end
          # make it private:
          private name
        end # registerControlClassProxy_i

=begin :nodoc:
    Use Reform::createInstantiator

    createInstantiator_i(string name)

    Create a private method within the application, with the given name, through
    which the class can be instantiated. In the app space all implementors
    generate a macro that is added to the implicit QMainWindow
=end
        def self.createInstantiator_i name, qt_implementor_class, reform_class, options = {}
          Instantiator.instantiator[name] = { qt_implementor_class: qt_implementor_class,
                                              reform_class: reform_class,
                                              options: options }
        end # App::createInstantiator_i
    end # module AppMacroContext


  private # methods of Reform

    def self.internalize dirprefix, hash
      dirprefix = File.dirname(__FILE__) + '/' + dirprefix if dirprefix[0] != '/'
      hash.each do |dir, klass|
        symlinks = {}
        for file in Dir["#{dirprefix}/#{dir}/*.rb"]
          basename = File.basename(file, '.rb')
          if File.symlink?(file)
            symlinks[basename.to_sym] = File.basename(File.readlink(file), '.rb').to_sym
          else
            send("registerKlassProxy", klass, basename, dir + '/' + basename)
          end
        end # Dir scan
        symlinks.each { |key, value| send("registerKlassProxy", klass, key, value) }
      end # each
    end

    def self.internalize_dir *dirs
      dirs = dirs[0] if dirs.length == 1 && Array === dirs[0]
      dirs.each do |dir|
        internalize dir, 'widgets'=>Widget, 'actions'=>AbstractAction,
                         'menus'=>Menu, 'graphics'=>GraphicsControl, 'models'=>AbstractModel,
                         'animations'=>Animation, 'states'=>AbstractState
      end
    end

    # some forwards, for the ultimate lazy programming:
    class Control < Qt::Object; end
    class GraphicsControl < Control; end
    class Widget < Control;  end
    class Frame < Widget; end
    class Layout < Control; end
    module Model; end
    class AbstractModel < Control; end
    class Animation < Control; end
    class AbstractState < Control; end
    class AbstractAction < Control; end
    class Menu < Control; end
    class App < Qt::Application; end

    # My idea was to keep these outside the real classes to avoid repeating myself
    # I abuse the fact that some Models are not (and need not be by design) AbstractModels...
    # As long as they include Model. So anything unknown becomes a Model....
    Contexts = { Widget=>[ControlContext, AppMacroContext],
                AbstractModel=>[ModelContext, AppMacroContext],
                Object=>[ModelContext],
                GraphicsControl=>[GraphicContext, SceneFrameMacroContext],
                Animation=>[AnimationContext, SceneFrameMacroContext],
                AbstractState=>[StateContext, SceneFrameMacroContext, AppMacroContext],
                Menu=>[MenuContext],
                AbstractAction=>[ActionContext]
                }

    def self.getContext4 klass
  #     tag "getContext4(#{klass})"
      Contexts[klass] || getContext4(klass.superclass)
    end

    # delegator. see App::registerControlClassProxy
    #  we add the X classProxy to those contexts in which we want the plugins
    # to become available.
    def self.registerKlassProxy klass, id, path = nil
      Contexts[klass].each { |ctxt| ctxt::registerControlClassProxy_i id, path }
    end

    # two in one if you want to use a class already loaded.
    #
    # Example:
    #
    #     registerKlass Widget, :mywidget, QMyWidget, MyWidget
    #
    # Parameters:
    # [abstractklass] Gives the baseclass (normally the directory would hint this). Can be one of:
    #                 - Widget
    #                 - AbstractModel
    #                 - GraphicsControl
    #                 - Animation
    #                 - AbstractState
    #                 - Menu
    #                 - AbstractAction
    #                 - Object, if all else fails
    # [id] string or symbol (preferred)
    # [qclass] the Qt implementor, may be nil
    # [effectiveklass] the Reform implementor, default is +Widget+
    #
    def self.registerKlass abstractklass, id, qclass, effectiveklass = abstractklass
      registerKlassProxy abstractklass, id
      createInstantiator id, qclass, effectiveklass
    end

    # delegator.
    # Called from all plugins, who in turn are loaded by a method created using register*Proxy_i
    #
    # Parameters:
    # [name] a string that should be File.basename(__FILE__, '.rb') in all cases
    # [qt_implementor_class] the Qt class to use. This may be nil
    # [reform_class] the reform class to use. The default is Widget
    # [options] Named parameters, with valid keys:
    #           [:form] boolean if the class is a ReForm or subclass. This is only
    #                   because sometimes the ReForm class is not known here so reform_class <= ReForm
    #                   will fail.
    def self.createInstantiator name, qt_implementor_class, reform_class = Widget, options = {}
  #     tag "createInstantiator(#{name.inspect})"
      # 'Widget' is implicit (since the default), and this 'require' avoids having to load it, as the caller may
      # be unaware of the fact that it is needed
      require 'reform/widget.rb' if reform_class == Widget && !reform_class.method_defined?(:whenPainted)
  #     tag "createInstantiator '#{name}' implementor=#{qt_implementor_class}, klass=#{reform_class}"
      # this can be done using classmethods in reform_class.
      # Also we can have ToplevelContext, included by App itself
      getContext4(reform_class).each do |ctxt|
  #     contextsToUse
  #     if contextsToUse.respond_to?(:each)
  #       contextsToUse.each do |ctxt|
        ctxt::createInstantiator_i name, qt_implementor_class, reform_class, options
      end
  #     else
  #       contextsToUse::createInstantiator_i name, qt_implementor_class, reform_class, options
  #     end
    end

  # the App is a basic Qt::Application extension. So see the qt docs as well.
  # Within an app there are 1 or more forms.
  # It is however possible to construct any Widget, AbstractState, Animation and AbstractModel.
  # # in that case we construct an implicit form and put everything in there.
    class App < Qt::Application
      include AppMacroContext
      private

        # shortcut. You can then say simple_data 'hallo', 'world'
        def simple_data *val
          ruby_model value: if val.length == 1 then val[0] else val end
        end

        alias :simpledata :simple_data

        def simplestruct *val
          structure value: if val.length == 1 then val[0] else val end
        end

  # You would normally pass ARGV here (not *ARGV). However the way to create a reform application is:
  #
  #    Reform::app {
  #      pluginname { prop1 value1; prop2 value2; .... }
  #      pluginname prop1: value1, prop2: value2, ....
  #      .....
  #    }
  #
  # What you normally store in an application would be MainWindow (mainwindow), Form (form) or Dialog (dialog)
  # If a block is passed to a plugin (or to +app+ itself) it is executed in the context of the instance
  # being setup. This means that private methods can be called.
  # Passing a hash is identical to passing a block. The properties are the setter methods to be
  # called. For multiargument setters the arguments must be put in an array:
  #
  #       Reform::app {
  #         form {
  #           sizeHint 400, 200
  #         }
  #       }
  #
  #       Reform::app {
  #         form sizeHint: [400, 200]
  #       }
  #
  # The idea is that the hash-form can be used for quick oneliners.
        def initialize *argv
          super
          # firstform points to the first form defined, which is the main form (mainwindow)
          @firstform = nil
          # forms is the list of all named forms (and only 'named' forms)
          @forms = {}
          # array of all forms
          @all_forms = []
          # title is used as caption
          @title = nil
          # instantiate a 'autoform' if no form has been given, default true
          @autoform = :form
          @doNotRun = false
        end

  # +autoform+ is normally true and indicates that the application will create
  # an implicit form, if a non-form widget is stored in it. You would want to
  # switch it off to create another toplevel window, like a simple button.
  # Example:
  #     Reform::app {
  #       button
  #    }
  # will create a form, plus a hbox layout implicitely, but:
  #     Reform::app {
  #       autoform false
  #       button
  #     }
  # will create a button as toplevel control
        def autoform value
          @autoform = value
        end

        # override, also a setter
        def startDragTime value = nil
          return super unless value
          setStartDragTime(MilliSeconds === value ? value.value : value)
        end

        # override, also a setter
        def startDragDistance value = nil
          return super unless value
          setStartDragDistance(value)
        end

      public # methods of Application

        # hash of all named(!!!) forms.
        attr :forms

        # array of all forms, named or not
        attr :all_forms

        # set when the first form is defined. This serves as the main window.
        # Do not use
        attr :firstform

        # for use with rspec tests:
        def doNotRun v = nil
          return @doNotRun if v.nil?
          @doNotRun = v
        end

        # called from Reform::app
        def setupForms
    #       tag "setupForms, firstform = #@firstform"
          # without any forms it loops, waiting until we quit.
          if @firstform
            @firstform.run
          elsif @all_forms.empty?
    #         tag "no forms registered"
            # I was tempted to put 'Hallo World' in this place:
            hello = Qt::PushButton::new tr('It Just Works')
            geometry = desktop.screenGeometry
            size = geometry.size / 2
            # ugly: qsize not excepted by moveTopLeft !!!
            topleft = Qt::Point.new(size.width, size.height)
            geometry.size = size
            geometry.moveTopLeft topleft / 2
            hello.geometry = geometry
            hello.show
          end
        end

          # this is a hack
        def menuBar quicky = nil, &block
          @firstform ||= mainwindow
                # we delay creating the elements until form.run is called.
      #           tag "create macro for #{name}"
          Macro.new(@firstform, :menuBar, quicky, block)
        end

        # return or set the title
        def title title = nil
          @title = title if title
          @title
        end

        # :nodoc: called without 'name' by ReForm::initialize, and with 'name'
        # by ReForm::name
        def registerForm aForm, name = nil
          if name
            # it is already in @all_forms !
            @forms[name] = aForm
            if name[-4, 4] == 'Form'
              $qApp.singleton_class.send(:define_method, name) { aForm }
            end
          end
          @all_forms << aForm
        end

        # Return a form by name
        def [](formname)
          @forms[formname]
        end
    end # class App

    # create an application, passing ARGV to it, then run it
    # Any block passed is executed in the constructor redirecting self to $qApp.
    def self.app &block
  #     tag "Creating Qt::Application!!"
      App.new ARGV
  #     tag "extend the Form class with the proper contributed widgets"

  #IMPORTANT, if any of the files loaded by these instantiators does not redefine the
  # instantiator this will cause a stack failure since we keep loading for ever...

      # Here I map directories to abstract base classes.
      internalize_dir '.', 'contrib'
      $qApp.instance_eval(&block) if block
  #     tag "CALLING app.exec"
      $qApp.setupForms
      $qApp.exec unless $qApp.doNotRun
    end # app method
end # module Reform

if __FILE__ == $0
  Reform::app
end