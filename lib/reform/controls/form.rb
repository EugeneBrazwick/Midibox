
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative 'frame'

=begin rdoc
 a ReForm is a basic form. It inherits Frame
 but is meant as a complete window.
=end
  class ReForm < Frame
    include ModelContext
    private
    def initialize qtc
#       tag "new ReForm, stacktrace=#{caller.join("\n")}"
      super self, qtc
      # store a ref to ourselves in the Qt::Widget
      @qtc.instance_variable_set :@_reform_hack, self
      # block to call for lazy initialization. After done so it becomes nil, can also be a 'quicky' hash
      @setup = nil #setupblock
      # the menubar implementor:
      @qmenuBar = nil
      # hash of Action objects, defined to be shared between menus
      @actions = {}
      # Proc to execute to setup the menu dynamically
      @contextMenuProc = nil
      # unpositioned forms should be centered (but only if size is set)
      @has_pos = false
      # callback blocks. The whenCanceled block can return 'false' to prevent
      # the cancel from closing the form (and false != nil in this case)
      @whenClosed = @whenCanceled = @whenInitialized = @whenShown = @whenConnected = nil
      # whenCommitted is called when the form is 'committed' ie, the changes
      # set are committed within the program
      @whenCommitted = nil
      # a form may have a single 'central' widget, together with border widgets like bars
      @qcentralWidget = nil
      @widget_index = {} # hash name=>widget
      # main model in the form, frames can override this locally though
      @model = nil
      $qApp.registerForm self
    end

    # IMPORTANT: the name becomes a method of $qApp, if and only if it ends
    # with the text 'Form' (not 'form'). Also $qApp.forms[name] be
    # used in all cases or even $qApp[name].
    # So you are encouraged to use names like myForm, mainForm, voiceForm etc..
    # It should also be possible to clone a registered form, for instance for
    # recursive structures. Only one of them can be registered within the application.
    def name aName
      @qtc.name = aName
      $qApp.registerForm self, aName
    end

    def central
      raise "'central' is meaningless for forms"
    end

        # override. PROBLEMATIC. Why is there no 'resized' signal ????
    # Why not make it then ???  For the time being.... FIXME
    # This can only be done if I change Qt::Widget#resizeEvent itself.
    # Otherwise I could use QWidget but any other Qt derivation will still
    # lack it!!!
    def resizeEvent event
      blk = @_reform_hack.whenResized and blk[event.size.width, event.size.height]
    end

    public
    # override. The containing form. We contain ourselves.
    def containing_form
      self
    end

    # returns a hash of form-local Actions, indexed by name
    attr_reader :actions

    alias :action :actions

    # returns a proc that has to setup the context menu
    attr_reader :contextMenuProc
    # set or return the central widget, if available
    attr_writer :qcentralWidget
    # setup is the proc passed to the RForm#run method
    attr_writer :setup
    attr_writer :qmenuBar

    # default
    def whenClosed &block
      if block
        @whenClosed = block
      else
        @whenClosed.call if @whenClosed
      end
    end

    # default whenCanceled handler returns nil always. So the form closes
    def whenCanceled &block
      if block
        @whenCanceled = block
      else
        @whenCanceled.call if @whenCanceled
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
        case @setup
        when Hash then setupQuickyhash(@setup)
        when Proc then instance_eval(&@setup)
        end
#         tag "calling Form.postSetup"
        postSetup
        # menubar without a centralwidget would remain invisible. That is confusing
        if @qtc.inherits('QMainWindow') &&
           (!@qcentralWidget && @all_widgets.length == 1 || @qmenuBar && @all_widgets.empty?)
=begin
  what to do if all_widgets is empty but you did put a control in there....
  it could be that it's widget? method returns false...
=end
=begin
    What if more than one control is stored in a main window?
    At this point we should probably insert a group and a layout??
    The least we can do is to warn that widgets will not be visible! It would probably be a solution
    to always add a groupbox in a mainwindow, but that would not be logical if there was actually
    exactly one element...
=end
          ctrl = if @all_widgets.empty? then button(tr('It Just Works!')) else @all_widgets[0] end
#           tag "ctrl=#{ctrl}"
          wrapper = Reform::Widget === ctrl && ctrl.qtc.widgetType?
          if wrapper || ctrl.qtc.widgetType?
            @qtc.centralWidget = if wrapper then ctrl.qtc else ctrl end
          end
#         puts "postprocessing setting of menuBar due to Qt bugs"
          # it must be AFTER centralWidget is set or else....
        end
        if @qmenuBar
          @qtc.layout = Qt::VBoxLayout.new(@qtc) unless @qtc.layout
          @qtc.layout.menuBar = @qmenuBar     # might just work for main windows as well? yes!
        end
      end
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
    end # ReForm#run

    # override
    def connectModel aModel, options = nil
      if aModel && name = aModel.name
        registerName name, aModel
      end
      super
    end

    # initial connection for a model. Automatically called when model is instantiated
    # with a form as parent
    # the form becomes an observer
    # set a new model
    def setModel aModel, quickyhash = nil, &initblock
      # this is required so the 'name' can  be set on model and it becomes a property of this
      # form. However it looks like a kludge, since models are basically shared between forms.
      aModel.containing_form = self if aModel
      super
    end

    def effectiveModel
      @model
    end

    #override, can be used to reregister a name with a different control
    def registerName aName, aControl
      aName = aName.to_sym
      if (@widget_index ||= {})[aName]
#       tag "removing old method '#{aName}'"
        (class << self; self; end).instance_eval do
          remove_method(aName)
        end
      end
      define_singleton_method(aName) { aControl }
      @widget_index[aName] = aControl
    end

    def [](i)
      @widget_index[i] or raise ReformError, tr("control '#{i}' does not exist")
    end

  end # class ReForm

  # using Qt::MainWindow is tempting, but MainWindow is rather stubborn.
  # you cannot add a layout for instance.
  # So form == generic toplevel widget
  #    mainwindow = mainwindow of application
  #    dialog == fixed size toplevel widget
  createInstantiator File.basename(__FILE__, '.rb'), Qt::Widget, ReForm, form: true

end # Reform
