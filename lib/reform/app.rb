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

  # use this to wrap a rescue clause around any block
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

=begin  rdoc
The Reform library is a qtruby based library for building gui's in a 100%
declarative way (we do not compromise!!!)
There are NO methods involved. Ever. Anywhere.

Requirements:
=========================================================
  - qt4.6
  - kdebindings_4.4.2
  - ruby1.9.2rc

Recepy for Ubuntu (of the Blood, Sweat and Tears Kind -- but in the end it was 'simply' this:)

Preliminaries:
  I hacked my ruby install on ubuntu (since 1.9.1 works fine),
  with a bunch of links (does not work with ruby1.8 installed as well):
    for i in erb rake ruby irb rdoc ri
    do
      sudo ln -s /usr/bin/${i}1.9.1 /etc/alternatives/$i
      sudo ln -s /etc/alternatives/$i /usr/bin/$i
    done
    cd /usr/lib
    sudo ln -s libruby-1.9.1.so libruby-1.9.so
    cd /usr/include/ruby-1.9.1/ruby
    sudo ln -s ../x86_64-linux/ruby/config.h
    sudo apt-get install libqt4-dev libasound2-dev rubygems1.9.1 subversion cmake autoconf
    sudo apt-get install kde-devel
  - download source from ubuntu (lucid)
  https://launchpad.net/ubuntu/lucid/+source/kdebindings/4:4.4.2-0ubuntu2
  - the following does not need the links above, accept the config.h one
  - cd /loadsofspace
  - tar zxf tarballs/kdebindings_4.4.2.orig.tar.gz
  - gunzip tarballs/kdebindings_4.4.2-0ubuntu2.diff.gz
  - patch < tarballs/kdebindings_4.4.2-0ubuntu2.diff
  - cd kdebindings-4.4.2/
  - cmake -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DRUBY_EXECUTABLE=/usr/bin/ruby1.9.1 \
      -DRUBY_INCLUDE_PATH=/usr/include/ruby-1.9.1 \
      -DRUBY_LIBRARY=/usr/lib/libruby-1.9.1.so \
      -DENABLE_QIMAGEBLITZ_SMOKE=off -DENABLE_ATTICA_SMOKE=off -DENABLE_KROSSRUBY=off -Wno-dev
  - make
  - sudo make install

IMPORTANT: RUBYLIB should be ~/Midibox/lib:/usr/local/lib/site_ruby/1.9.1:/usr/local/lib/site_ruby/1.9.1/x86_64-linux
But why?? It worked fine first...

DIAGNOSTICS:
 Q: ERROR: cmake/modules/FindKDE4Internal.cmake not found in ...
 A: kde-devel kdelibs5-dev  (presumably???)  NOT kdelibs4-dev!
 Q: on any failure?
 A: cd ..; rm -rf kdebindings-4.4.2  # and repeat from start after fixing!

Note: it builds far too much... So takes an hour. Feel free to skip more by disabling more
    modules. For your convenience:
      -DENABLE_QTWEBKIT_SMOKE=off -DENABLE_QTSCRIPT_SMOKE=off \
      -DENABLE_QTUITOOLS_SMOKE=off -DENABLE_QTTEST_SMOKE=off -DENABLE_PHONON_SMOKE=off  \
      -DENABLE_QSCI_SMOKE=off -DENABLE_QWT_SMOKE=off -DENABLE_KDE_SMOKE=off \
      -DENABLE_KDEVPLATFORM_SMOKE=off -DENABLE_KHTML_SMOKE=off -DENABLE_KTEXTEDITOR_SMOKE=off \
      -DENABLE_SOLID_SMOKE=off -DENABLE_PLASMA_SMOKE=off -DENABLE_QTWEBKIT_RUBY=off \
      -DENABLE_QTUITOOLS_RUBY=off -DENABLE_QTSCRIPT=off  -DENABLE_QTTEST=off -DENABLE_PHONON_RUBY=off \
      -DENABLE_QSCINTILLA_RUBY=off -DENABLE_QWT_RUBY=off -DENABLE_SOPRANO_RUBY=off  \
      -DENABLE_KDEVPLATFORM_RUBY=off -DENABLE_KORUNDUM_RUBY=off -DENABLE_KHTML_RUBY=off \
      -DENABLE_KTEXTEDITOR_RUBY=off -DENABLE_SOLID_RUBY=off -DENABLE_PLASMA_RUBY=off \

However, this is uncharted territory. The modules I disabled had to be disabled because the
compile failed.

About the 'qt4-qtruby' package. This package is for ruby1.8. You can download the source and compile
it for ruby1.9.1 but it will never work (it did for karmic though).
qtruby is now officially part of kdebindings, I guess.

# with ruby 1.9.2rc1 compilation fails at 96% as STR2CSTR is missing: I added the following in
  krubypluginfactory.cpp:
#define STR2CSTR StringValueCStr
    VALUE ara1 = rb_obj_as_string(info);        plus use this iso original...
         .....   .arg( STR2CSTR(ara1) )
....

CONCEPTS
========================================

Shoes (as in 'stolen from')

But 'shoes' is too much a toy.

The idea is to map a datastructure one-on-one on a form. By picking the controls
you can make any view for a model.

Richard Dale has made two qtruby modelsystems that can be used for ActiveRecord and
ActiveResource.
I would like to add one for Object. Or even BasicObject. Because any ruby instance is
obviously a model.

=end

# FIXME
=begin
to_variant is LETAL
because the object may well be no longer referenced.
Then it is disposed off.
BAD IDEA

class Object
  def to_variant
#= begin DOES NOT WORK
#    Reform::Variant.new self
# =e nd
    Qt::Variant.new object_id
  end
end

class Qt::Variant
  def to_object
    ObjectSpace._id2ref(to_int)
  end
end
=end

module Reform

=begin DOES NOT WORK AT ALL
  # taken from kde qtruby introduction page:
  # http://techbase.kde.org/Development/Languages/Ruby#QtRuby
  class Variant < Qt::Variant
    private
    def initialize(value)
        super()
        @value = value
    end
    public
    # I feel rather cheap about this:
    attr_accessor :value
  end
=end

  class Error < StandardError
  end

  ReformError = Error

=begin rdoc
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
#       tag "Defining method #{self}.#{name}"  It may return nil on exceptions... THis is by design
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
            # you cannot store a layout in a layout, nor can you store a layout in a graphicsscene.
            # See calendar.cpp in Nokia examples. layout.addLayout is OK.
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
  module ControlContext
    extend Instantiator
  end # module ControlContext

  WidgetContext = ControlContext

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
      list = list[0] if list && Array === list
      list.each { |action| add(containing_form.action(action), nil) }
    end
  end

#   module DelegateContext
#     extend Instantiator
#   end
#
#   module ToplevelContext
#     extend Instantiator
#   end

  # this class just stores a name with the arguments to a widget constructor
  class Macro
  private
    def initialize control, name, quicky, block
      raise unless control
#       tag "Macro.new(#{control}, #{name})"
      @control, @name, @quicky, @block = control, name, quicky, block
      # WTF??? macros have not a name perse, so macros[name] = self DESTROYS macros!!!!
      control.macros! << self
    end
  public
    def exec receiver = nil
#       tag "executing macro #{@control.class}::#@name, args=#@quicky, block=#@block"
      (receiver ||= @control).send(@name, @quicky, &@block) #.tap do |t|
#         tag "macroresult is #{t}"
#       end
    end
#         attr :quickylabel, :block
    attr :name

    def to_s
      "#{@control.class}::#@name(#{@quicky}) BLOCK #{@block.inspect}"
    end
  end # class Macro
#

  # experimental. 'Cans' graphicitem setups
  module SceneFrameMacroContext
    def self.createInstantiator_i name
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

  private

  def self.internalize hash
    hash.each do |dir, klass|
      symlinks = {}
      for file in Dir["#{File.dirname(__FILE__)}/#{dir}/*.rb"]
        basename = File.basename(file, '.rb')
        if File.symlink?(file)
          symlinks[basename.to_sym] = File.basename(File.readlink(file), '.rb').to_sym
        else
          send("register#{klass}ClassProxy", basename, dir + '/' + basename)
        end
      end
      symlinks.each { |key, value| send("register#{klass}ClassProxy", key, value) }
    end
  end

  # delegator. see App::registerControlClassProxy
  def self.registerControlClassProxy id, path
    ControlContext::registerControlClassProxy_i id, path
    App::registerControlClassProxy_i id, path
  end

  # two in one if you want to use a class already loaded
  def self.registerControlClass id, qclass, klass = Widget
    registerControlClassProxy id, nil
    createInstantiator id, qclass, klass
  end

  def self.registerModelClass id, klass
    registerModelClassProxy id, nil
    createInstantiator id, nil, klass
  end

  def self.registerGraphicsControlClassProxy id, path
#     tag "registerGraphicsControlClassProxy(#{id}, #{path})"
    GraphicContext::registerControlClassProxy_i id, path
    SceneFrameMacroContext::registerControlClassProxy_i id, path
  end

  def self.registerModelClassProxy id, path
    ModelContext::registerControlClassProxy_i id, path
    App::registerModelClassProxy_i id, path
  end

  def self.registerMenuClassProxy id, path
#     tag "Adding method '#{id}' to MenuContext"
    MenuContext::registerControlClassProxy_i id, path
  end

  def self.registerActionClassProxy id, path
    ActionContext::registerControlClassProxy_i id, path
  end

  # some forwards, for the ultimate lazy programming:
  class Control < Qt::Object
  end

  class Widget < Control
  end

  class Frame < Widget
  end

  class Layout < Control
  end

  module Model
  end

  # delegator.
  # Called from all plugins, who in turn are loaded by a method created using register*Proxy_i
  def self.createInstantiator name, qt_implementor_class, reform_class = Widget, options = {}
#     tag "createInstantiator(#{name.inspect})"
    # 'Widget' is implicit (since the default), and this 'require' avoids having to load it, as the caller may
    # be unaware of the fact that it is needed
    require 'reform/widget.rb' if reform_class == Widget && !reform_class.method_defined?(:whenPainted)
#     tag "createInstantiator '#{name}' implementor=#{qt_implementor_class}, klass=#{reform_class}"
    # this can be done using classmethods in reform_class.
    # Also we can have ToplevelContext, included by App itself
    contextsToUse = reform_class.contextsToUse
    if contextsToUse.respond_to?(:each)
      contextsToUse.each do |ctxt|
        ctxt::createInstantiator_i name, qt_implementor_class, reform_class, options
      end
    else
      contextsToUse::createInstantiator_i name, qt_implementor_class, reform_class, options
    end
  end

=begin rdoc
  the App is a basic Qt::Application extension. So see the qt docs as well.
  I use 'exec_i' from Reform::app
=end
  class App < Qt::Application
#     include ToplevelContext
    private

=begin rdoc
the application constructor is passed the commandline. Or any splat for that matter.
The idea is that it is a singleton.
=end
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

=begin rdoc
    normally, value would be false so @autoform is switched of.
Example:
    Reform::app {
      button
   }
will create a form, plus a hbox implicitely, but:
    Reform::app {
      autoform false
      button
    }
will create a button as toplevel control
=end
    def autoform value
      @autoform = value
    end

    public

    # hash of all named(!!!) forms.
    attr :forms

    # array of all forms, named or not
    attr :all_forms

    # set when the first form is defined. This serves as the main window.
    attr :firstform

    # for use with rspec tests:
    def doNotRun v = nil
      return @doNotRun if v.nil?
      @doNotRun = v
    end

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

    def self.registerModelClassProxy_i name, thePath
      self.registerControlClassProxy_i name, thePath
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

=begin
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

    # return or set the title
    def title title = nil
      @title = title if title
      @title
    end

    # called without 'name' by ReForm::initialize, and with 'name'
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

    # delegate to @forms
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

    internalize 'controls'=>'Control', 'actions'=>'Action', 'contrib_widgets'=>'Control',
                'menus'=>'Menu', 'graphics'=>'GraphicsControl', 'models'=>'Model'
    $qApp.instance_eval(&block) if block
#     tag "CALLING app.exec"
    $qApp.setupForms
    $qApp.exec unless $qApp.doNotRun
  end # app method
end # module Reform

if __FILE__ == $0
  Reform::app
end