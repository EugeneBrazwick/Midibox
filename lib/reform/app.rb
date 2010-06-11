
# Copyright (c) 2010 Eugene Brazwick

verb, $VERBOSE = $VERBOSE, false
require 'Qt'
$VERBOSE = verb

# for debugging purposes only
# if $DEBUG
module Kernel

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

  def tag msg
    # avoid puts for threading problems
    STDERR.print "#{File.basename(caller[0])} #{msg}\n"
  end

  # this is the ugly way to make 'with' in ruby. CURRENT STATE: unused
  def with arg, &block
    arg.instance_eval(&block)
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
  - ruby1.9.1

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

DIAGNOSTICS:
 Q: ERROR: cmake/modules/FindKDE4Internal.cmake not found in ...
 A: kde-devel kdelibs5-dev  (presumably???)  NOT kdelibs4-dev!
 Q: on any failure?
 A: cd ..; rm -rf kdebingins-4.4.2  # and repeat from start after fixing!

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

  class ReformError < StandardError
  end

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
    def createInstantiator_i name, qt_implementor_class, reform_class, options = nil
#       tag "define_method #{self}::#{name}."
      remove_method name if private_method_defined?(name)
      define_method name do |quickyhash = nil, &block|
        raise 'cannot use both argument AND a block' if quickyhash && block
#         tag "arrived in #{self}::#{name}()"
        # It's important to use parent_qtc_to_use, since it must be a true widget.
        # Normally, 'qparent' would be '@qtc' itself
        qparent = parent_qtc_to_use_for(reform_class)
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
        if qparent
          graphic_parent = qparent.inherits('QGraphicsScene')
          if reform_class <= Layout
            # assuming that qt_implementor_class <= QLayout, and layout is
            # constructed with parent == 0 (see for example widgets/calendar/window.cpp )
            #             && #(qparent.widgetType? && qparent.layout ||
            # insert an additional generic frame (say Qt::GroupBox)
            # you cannot store a layout in a layout, nor can you store a layout in a graphicsscene.
            # See calendar.cpp in Nokia examples. layout.addLayout is OK.
            if graphic_parent # storing layout in graphic, requires some widget in between:
              qparent = Qt::GroupBox.new qparent
              ctrl = addControl GroupBox.new(ctrl, qparent)
            end
            qparent = nil
          elsif graphic_parent # see above && !(reform_class <= GraphicsItem)
            qparent = nil
#     you cannot store a QWidget in a g-scene but since it accepts QGraphicsItems it is possible to
#     create a QGraphicsProxyWidget
          end
        end  # if qparent
        # we create the implementor first, then the wrapper
#         tag "reform_class=#{reform_class}, calling new_qt_implementor for #{qt_implementor_class}, parent=#{qparent}"

THIS ALL NO LONGER APPLIES since parent_qtc_to_use_for returns nil for layouts...
=end
        qparent = nil if qparent && qparent.inherits('QGraphicsScene')
#         tag "instantiate #{qt_implementor_class} with parent #{qparent}"
        newqtc = qt_implementor_class &&
                 ctrl.instantiate_child(reform_class, qt_implementor_class, qparent)
#         tag "#{reform_class}.new, ctrl=#{ctrl} self=#{ctrl}, func=#{name}"
        if reform_class <= Model
#           tag "CALLING setModel!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
          ctrl.setModel(c = reform_class.new, quickyhash, &block)
        else
          c = reform_class.new ctrl, newqtc
#           tag "instantiated c=#{c}, parent is a #{ctrl.class}"
#           c.text(quickylabel) if quickylabel
          # addControl will execute block, and then also call postSetup
#           tag "APP -> #{ctrl.class}.addControl(#{c.class})"
          ctrl.addControl(c, quickyhash, &block)
        end
#         tag "IMPORTANT: method '#{name}' return the control #{c}"
        c
      end  # define_method name
      # make the method private:
      private name
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
    # the unit loaded should call registerControlClass which overwrites
    # our method!
    #
    # For internal use only.
    def registerControlClassProxy_i name, thePath
      # to avoid endless loops we must consider that by loading some classes it is possible
      # that we already loaded the file.
      # even more it is possible that frame.rb was loaded before we ever got to registering the proxies
      # in that case we would overwrite the correct method with the proxy. BAD.
      # if the method already exists, then we may assume it is the right one!
      return if private_method_defined?(name)
      klass = self
#       tag "define_method #{self}::#{name}"
      define_method name do |quickylabel = nil, &block|
#         tag "arrived in #{self}::#{name}() PROXY"
        # when called the method is removed to prevent loops
        klass.send :remove_method, name
#         tag "require_relative '#{thePath}'"
        require_relative thePath
        # the loaded module should call registerControlClass which recreates the method
        # and we call it immediately
#         tag "calling the new #{name} method, and returning ?"
        send(name, quickylabel, &block) #.tap { |t| tag "and returning #{t}" }
      end
      private name
    end
  end # module Instantiator

  # ControlContext means we get the instantiators in the 'controls' directory.
  # So things including ControlContext can contain other widgets
  module ControlContext
    extend Instantiator
  end # module ControlContext

  # GraphicContext means we get the instantiators in the 'graphics' directory.
  module GraphicContext
    extend Instantiator
  end # module GraphicContext

  # ModelContext means we can create models for the control that includes it
  # These are all in the 'models' subdirectory
  module ModelContext
    extend Instantiator
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
      list.each do |action|
        act = containing_form.action[action] or raise ReformError, tr("No such action: '%s'" % action)
        addAction act
      end
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
#           tag "Macro.new(#{control}, #{name})"
      @control, @name, @quicky, @block = control, name, quicky, block
      control.macros! << self
    end
  public
    def exec receiver = nil
#       tag "executing macro #{@control.class}::#@name, args=#@quicky"
      (receiver ||= @control).send(@name, @quicky, &@block) #.tap do |t|
#         tag "macroresult is #{t}"
#       end
    end
#         attr :quickylabel, :block
    attr :name

    def to_s
      "#{@control.class}::#@name(#{@quickylabel}) BLOCK #{@block.inspect}"
    end
  end # class Macro
#

  # experimental. 'Cans' both widgets and graphicitem setups
  module SceneFrameMacroContext
    def self.createInstantiator_i name
#       tag "define_method #{self}::#{name} MACRO recorder"
      define_method name do |quickylabel = nil, &block|
#         tag "Recording macro for #{self}::#{name}(), containing_frame=#{containing_frame}"
        Macro.new(self, name, quickylabel, block)
      end
      private name
    end

    def self.registerControlClassProxy_i name, thePath
      return if private_method_defined?(name)
      klass = self
      define_method name do |quickylabel = nil, &block|
        klass.send :remove_method, name
        require_relative thePath
        send(name, quickylabel, &block)
      end
      private name
    end

  end # module SceneFrameMacroContext

  private

  # delegator. see App::registerControlClassProxy
  def self.registerControlClassProxy id, path
    ControlContext::registerControlClassProxy_i id, path
    App::registerControlClassProxy_i id, path
  end

  def self.registerGraphicsControlClassProxy id, path
#     tag "registerGraphicsControlClassProxy(#{id}, #{path})"
    GraphicContext::registerControlClassProxy_i id, path
#     SceneFrameMacroContext::registerControlClassProxy_i id, path
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

#   def self.registerDelegateClassProxy id, path
#     DelegateContext::registerControlClassProxy_i id, path
#   end

#   require_relative 'widget'

  # some forwards, for the ultimate lazy programming:
  class Control < Qt::Object
  end

  class Widget < Control
  end

#   class Menu < Control
#   end
#
#   class Action < Control
#   end
#
  class Frame < Widget
  end

  class Layout < Frame
  end

  module Model
  end

  # delegator. See App::createInstantiator
  def self.createInstantiator name, qt_implementor_class, reform_class = Widget, options = {}
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

=begin
  registerControlClassProxy_i(string name, string relativepath)
  create a method 'theName' within the caller class, the implementor
  must be located in the file with the designated path (which must be relative).
  If the method already exists, this is silenty ignored and nothing is done.
  The method will have an optional argument 'label', and a block for initialization.
  It basically delegates to the application, using send.

  Use through Reform::registerControlClassProxy
=end
    def self.registerControlClassProxy_i name , thePath
#       tag "registerControlClassProxy_i(#{name}, #{thePath})"
      return if private_method_defined?(name)
#       tag "define_method #{self}::#{name}"
      define_method name do |quickylabel = nil, &block|
        # Remove ourselves, so if we accidentally come back here we cause no stack overflow
        App.send :remove_method, name
        require_relative thePath
        send(name, quickylabel, &block)
      end
      # make the method private:
      private name
    end

    def self.registerModelClassProxy_i name, thePath
      self.registerControlClassProxy_i name, thePath
#       return if private_method_defined?(name)
#       define_method name do |quickylabel = nil, &block|
#         App.send :remove_method, name
#         require_relative thePath
#         send(name, quickylabel, &block)
#       end
#       private name
    end

    # override! called from Reform::app
    def exec
#       tag "exec"
      # without any forms it loops, waiting until we quit.
      @firstform.run if @firstform
  #     puts "activeWindow = #{activeWindow.inspect}"
      unless activeWindow
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
      super
    end # App#exec

=begin
  Use Reform::createInstantiator

  createInstantiator_i(string name)

  Create a private method within the application, with the given name, through
  which the class can be instantiated. In the app space all implementors
  generate a macro that is added to the implicit QMainWindow
=end
    def self.createInstantiator_i name, qt_implementor_class, reform_class, options = {}
      remove_method name if private_method_defined?(name)
      if options[:form]
        define_method name do |quicky = nil, &block|
          qform = qt_implementor_class.new
          form = reform_class.new qform
          @firstform ||= form   # it looks the same, but is completely different
          form.setup = quicky ? quicky : block
          # and now we wait for 'run'
          form
        end
      else
        define_method name do |quicky = nil, &block|
          if @autoform
            raise ReformError, 'put controls in forms' unless @all_forms.length <= 1
            # it seems that 'form' is not the instantiator here??
  #           tag "form=#{form.inspect}"  -> NIL
#             tag "Instantiating autoform '#@autoform', unless #@firstform"
            @firstform ||= send(@autoform)
            # we delay creating the elements until form.run is called.
  #           tag "create macro for #{name}"
            Macro.new(@firstform, name, quicky, block)
          else
            # is this a proper constraint?
            raise ReformError, 'only 1 control can be on top' if @firstform
            qctrl = qt_implementor_class.new
#             tag "reform_class=#{reform_class}, qctrl=#{qctrl}"
            @firstform = reform_class.new(nil, qctrl)
          end
        end
      end
      # make it private:
      private name
    end # App::createInstantiator_i

    # return or set the title
    def title title = nil
      @title = title if title
      @title
    end

    # set when the first form is defined. This serves as the main window.
    attr :firstform

    # called without 'name' by ReForm::initialize, and with 'name'
    # by ReForm::name
    def registerForm aForm, name = nil
      if name
        # it is already in @all_forms !
        @forms[name] = aForm
        if name[-4, 4] == 'Form'
          $qApp.singleton_class.send(:define_method, name) { aForm }
        end
      else
        @all_forms << aForm
      end
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
    for file in Dir[File.dirname(__FILE__) + '/controls/*.rb']
      basename = File.basename(file, '.rb')
      registerControlClassProxy basename, 'controls/' + basename
    end
    for file in Dir[File.dirname(__FILE__) + '/menus/*.rb']
      basename = File.basename(file, '.rb')
      registerMenuClassProxy basename, 'menus/' + basename
    end
    for file in Dir[File.dirname(__FILE__) + '/actions/*.rb']
      basename = File.basename(file, '.rb')
      registerActionClassProxy basename, 'actions/' + basename
    end
    for file in Dir[File.dirname(__FILE__) + '/contrib_widgets/*.rb']
      basename = File.basename(file, '.rb')
      registerControlClassProxy basename, 'contrib_widgets/' + basename
    end
  #IMPORTANT, if any of the files loaded by these instantiators does not redefine the
  # instantiator this will cause a stack failure since we keep loading for ever...
    for file in Dir[File.dirname(__FILE__) + '/graphics/*.rb']
      basename = File.basename(file, '.rb')
      registerGraphicsControlClassProxy basename, 'graphics/' + basename
    end
    for file in Dir[File.dirname(__FILE__) + '/models/*.rb']
      basename = File.basename(file, '.rb')
#       tag "registerModelClassProxy #{basename} -> models/#{basename}.rb"
      registerModelClassProxy basename, 'models/' + basename
    end
#     for file in Dir[File.dirname(__FILE__) + '/delegates/*.rb']
#       basename = File.basename(file, '.rb')
#       registerModelClassProxy basename, 'delegates/' + basename
#     end
    $qApp.instance_eval(&block) if block
#     tag "CALLING app.exec"
    $qApp.exec
  end # app
end # module Reform

if __FILE__ == $0
  Reform::app
end