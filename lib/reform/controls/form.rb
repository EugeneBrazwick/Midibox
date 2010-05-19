
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
      # block to call for lazy initialization. After done so it becomes nil
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

    public
    # override. The containing form. We contain ourselves.
    def containing_form
      self
    end

    # returns a hash of form-local Actions, indexed by name
    attr_reader :actions
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
    def run &setup
      @setup = setup if setup
      if @setup || @macros
        # without a block windowTitle is never set. Nah...
        title = $qApp.title
        @qtc.windowTitle = title if title
        instance_eval(&@setup) if @setup
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
      connectModel(@model, initialize: true) if @model
      # note: originally BEFORE the assign to activeWindow...
      @qtc.show
      @qtc.raise
    end # ReForm#run

    # initial connection for a model. Automatically called when model is instantiated
    # with a form as parent
    # the form becomes an observer
    def setModel model, &block
      @model.removeObserver_i(self) if instance_variable_defined?(:@model)
      @model = model
      if @model
        @model.containing_form = self
        @model.instance_eval(&block) if block
        @model.postSetup
        @model.addObserver_i self
      end
      #  TOO SOON ! connectModel @model, initialize: true
    end

    #override
    def registerName aName, aControl
      aName = aName.to_sym
      define_singleton_method(aName) { aControl }
      (@widget_index ||= {})[aName] = aControl
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
