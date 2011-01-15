
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative 'frame'
  require 'reform/undo'

=begin rdoc
 a ReForm is a basic form. It inherits Frame
 but is meant as a complete window.

=end
  class ReForm < Frame
    include ModelContext, StateContext

    private

      # NOTE: due to a qtruby hack this is called twice per 'new'!!!
      # But the first time it never goes beyond 'super'!
      def initialize qtc
  #       tag "#{self}.initialize(#{qtc}), stacktrace=#{caller.join("\n")}"
        super nil, qtc
        # store a ref to ourselves in the Qt::Widget
        # block to call for lazy initialization. After done so it becomes nil, can also be a 'quicky' hash
        @setup = nil #setupblock
        # the menubar implementor:
  #       @qmenuBar = nil
        # Proc to execute to setup the menu dynamically
        @contextMenuProc = nil
        # unpositioned forms should be centered (but only if size is set)
  #       @has_pos = false
        # callback blocks. The whenCanceled block can return 'false' to prevent
        # the cancel from closing the form (and false != nil in this case)
        @whenClosed = @whenCanceled = @whenInitialized = @whenShown = nil
        @whenConnected = nil
          # DO NOT SET whenConnected to nil!! ????
        # whenCommitted is called when the form is 'committed' ie, the changes
        # set are committed within the program
        @whenCommitted = nil
        # a form may have a single 'central' widget, together with border widgets like bars
        @qcentralWidget = nil
        @control_index = {} # hash name=>widget
        # main model in the form, frames can override this locally though
#         @model = nil
  #       tag "calling registerForm #{self}"
        $qApp.registerForm self
  #       tag "ReForm.new EXECUTED"
        @undostack = QUndoStack.new(self)
        $undo.addStack(@undostack)
        @parametermacros = {} # hash name -> macroarray
        @brushes = {} # indexed by name
        @pens = {} # indexed by name
        @itemgroups = {} # ""
        @colors = {}
        @fonts = {}
      end

      # IMPORTANT: the name becomes a method of $qApp, if and only if it ends
      # with the text 'Form' (not 'form'). Also $qApp.forms[name] be
      # used in all cases or even $qApp[name].
      # So you are encouraged to use names like myForm, mainForm, voiceForm etc..
      # It should also be possible to clone a registered form, for instance for
      # recursive structures. Only one of them can be registered within the application.
      def name aName = nil
        return super unless aName
        @qtc.name = aName
        $qApp.registerForm self, aName
      end

      def central
        raise "'central' is meaningless for forms"
      end

    public

      def registerBrush name, brush
        case brush
        when Qt::Brush then @brushes[name] = brush
        when Graphical::Brush then @brushes[name] = brush.qtc
        when Graphical::Gradient then @brushes[name] = Qt::Brush.new(brush.qtc)
        else raise "Cannot register a #{brush.class}"
        end
      end

      def registerPen name, pen
        case pen
        when Qt::Pen then @pens[name] = pen
        when Graphical::Pen then @pens[name] = pen.qtc
        else raise "Cannot register a #{pen.class}"
        end
      end

      def registerFont name, font
        case font
        when Qt::Font then @fonts[name] = font
        when Graphical::Font then @fonts[name] = font.qtc
        else raise "Cannot register a #{font.class}"
        end
      end

      def registeredPen(name)
        @pens[name]  # THIS IS EVIL || :black
      end

      def registeredBrush(name)
        @brushes[name] # ... || :white
      end

      def registeredFont(name)
        @fonts[name]
      end

      # override. The containing form. We contain ourselves.
      def containing_form
        self
      end

      # Luxury version of []. Some typechecking is done.
      def action name
        r = self[name] or raise ReformError, tr("No such action: '%s'") % name.to_s
        unless r.action?
          raise ReformError, tr("Type mismatch '%s' is no action (but a %s)") % [name.to_s, r.class]
        end
        r
      end

      # returns a proc that has to setup the context menu
      attr_reader :contextMenuProc

      # set or return the central widget, if available
      attr_writer :qcentralWidget

      # setup is the proc passed to the RForm#run method
      attr_writer :setup

      # called when the form is closed. NOT! Not implemented yet.
      def whenClosed &block
        if block
          @whenClosed = block
        else
          rfCallBlockBack(&@whenClosed) if @whenClosed
        end
      end

      # default whenCanceled handler returns nil always. So the form closes
      # Not implemented yet
      def whenCanceled &block
#         tag "whenCanceled"
        if block
          @whenCanceled = block
        else
          !@whenCanceled || rfCallBlockBack(&@whenCanceled)
        end
      end

      # called after the first raise, when the form is executed and visible.
      # Not the same as responding to showEvent(!!) since this is called
      # every time the form comes on top.
      def whenShown &block
        if block
          @whenShown = block
        else
          rfCallBlockBack(&@whenShown) if @whenShown
        end
      end

      # execute the form. The passed block is instance-evalled and recorded in @setup.
      # if no centralWidget is set, the first control is appointed to this task.
      # Assigns the menuBar (provided a setup block was passed)
      # We call show + raise.
      # If this is the first form declared, it is assigned to the Qt ActiveWindow.
      def run # &setup
  #       @setup = setup if setup
  #             raise 'it seems setup is always nil???' if @setup   # BS
        if @setup || instance_variable_defined?(:@macros) && @macros
          # without a block windowTitle is never set. Nah...
          title = $qApp.title
          @qtc.windowTitle = title if title
  #         tag "setup=#@setup"
          case @setup
          when Hash then setupQuickyhash(@setup)
          when Proc then instance_eval(&@setup)
          end
  #         tag "calling #{self}#postSetup"
          postSetup
          # menubar without a centralwidget would remain invisible. That is confusing

  #         if @qmenuBar
  #           @qtc.layout = Qt::VBoxLayout.new(@qtc) unless @qtc.layout
  #           @qtc.layout.menuBar = @qmenuBar     # might just work for main windows as well? yes!
  #         end
        end
  #       tag "self=#{self}, firstform=#{$qApp.firstform}"
        if self == $qApp.firstform
          # if unambigous center widget... Set it to tell application there is some window
  #         tag "assigning activeWindow"
          $qApp.activeWindow = @qtc
        end
        # connecting the model is cheaper when the form is still invisible
  #       setModel(@model) if instance_variable_defined?(:@model) && @model ??
        # note: originally BEFORE the assign to activeWindow...
  #       tag "qtc=#@qtc"
        @qtc.show
        @qtc.raise
        whenShown
      end # ReForm#run

      # override
#       def updateModel aModel, options = nil
#         if aModel && (name = aModel.name)
#           registerName name, aModel
#         end
#         super
#       end

      # override
#       def effectiveModel
#         @model
#       end

      #override, can be used to reregister a name with a different control
      def registerName aName, aControl
        aName = aName.to_sym
        if (@control_index ||= {})[aName]
  #       tag "removing old method '#{aName}'"
          (class << self; self; end).instance_eval do
            remove_method(aName)
          end
        end
        define_singleton_method(aName) { aControl }
        @control_index[aName] = aControl
      end

      # return a named control, it must be present
      def [](symbol)
        @control_index[symbol] or raise ReformError, tr("control '#{symbol}' does not exist")
      end

#       attr_writer :model

      attr :undostack
      attr :parametermacros

  end # class ReForm

  module QFormHackContext
    include QWidgetHackContext

    public

      def closeEvent event
#         tag "#{self}::closeEvent(#{event.inspect})"
        if @_reform_hack.whenCanceled
          event.accept
          @_reform_hack.whenClosed
          $undo.removeStack(@_reform_hack.undostack)
        else
          event.ignore
        end
      end

#       def focusInEvent event
#         super

      def showEvent event
        super
        $undo.activeStack = @_reform_hack.undostack
      end
  end

  # using Qt::MainWindow is tempting, but MainWindow is rather stubborn.
  # you cannot add a layout for instance.
  # So form == generic toplevel widget
  #    mainwindow = mainwindow of application
  #    dialog == fixed size toplevel widget
  # Event though it is a QWidget, minimumSizeHint never seems to be called for the toplevel widget....(?)
  class QForm < Qt::Widget
    include QFormHackContext

    private

  end


  createInstantiator File.basename(__FILE__, '.rb'), QForm, ReForm, form: true

end # module Reform