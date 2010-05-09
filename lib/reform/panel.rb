
module Reform

  require_relative 'widget'

=begin rdoc

a Panel is a widget that may contain others.
=end
  class Panel < Widget

    private

    def initialize panel, qtc
      super
      # all immediate controls within this panel are in here
      # but also the controls added to Layouts, since Qt layouts does not own them.
      @all_widgets = []
    end

    public

    def self.createInstantiator_i name, qt_implementor_class, reform_class
      define_method name do |quickylabel = nil, &block|
        # It's important to use parent_qtc_to_use, since it must be a true widget.
        # Normally, 'qparent' would be '@qtc' itself
        qparent = parent_qtc_to_use
=begin
    Severe problem:     sometimes the parenting must change but how can this be done before
                        even the instance exists?
    Example: creating a Qt::Layout with parent Qt::MainWindow will fail!
    Answer: HACK IT!
=end
        ctrl = self
#         graphicsproxy = false
#         puts "#{File::basename(__FILE__)}:#{__LINE__}: qparent(#{qparent}).respond_to:layout == #{parent.respond_to?(:layout)}"
  # the smoke hacks prevent this from working since internally Qt::VBoxLayout subclasses Qt::Base !!!
# Oh my GOD!!
# NOT GOING TO WORK.
#  BAD respond_to is USELESS!!        if qparent.respond_to?(:layout) && qparent.layout && reform_class <= Layout  # smart!!
        if qparent
          if reform_class <= Layout && (qparent.inherits('QWidget') && qparent.layout || qparent.inherits('QGraphicsScene'))
            # insert an additional generic panel (say Qt::GroupBox)
            # you cannot store a layout in a layout, nor can you store a layout in a graphicsscene.
            if qparent.inherits('QGraphicsScene') # even if a GraphicsItem, you cannot pass the scene as a qparent! && !(reform_class <= GraphicsItem)
              qparent = nil
              # but now we must later call orgparent.addWidget(qparent)
            end
            qparent = Qt::GroupBox.new qparent
            ctrl = addControl GroupBox.new(ctrl, qparent)
          elsif qparent.inherits('QGraphicsScene') # see above && !(reform_class <= GraphicsItem)
            qparent = nil
=begin
    you cannot store a QWidget in a g-scene but since it accepts QGraphicsItems it is possible to
    create a QGraphicsProxyWidget
=end
          end
        end  # if qparent
        newqtc = reform_class.new_qt_implementor(qt_implementor_class, qparent)
        c = reform_class.new ctrl, newqtc
        c.text = quickylabel if quickylabel
        ctrl.addControl(c, &block)
      end  # define_method name
      # make the method private:
      private name
    end # createInstantiator

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
    # Problematic: we run initializers in the context of Panel.
    # But this 'eval' adds them to ReForm instead.
    #
    # Do not call, use Reform::registerControlClassProxy
    def self.registerControlClassProxy_i theName, thePath
      # to avoid endless loops we must consider that by loading some classes it is possible
      # that we already loaded the file.
      # even more it is possible that panel.rb was loaded before we ever got to registering the proxies
      # in that case we would overwrite the correct method with the proxy. BAD.
      # if the method already exists, then we may assume it is the right one!
      return if private_method_defined?(theName)
      # when called the method is removed to prevent loops
      # the loaded module should call registerControlClass !
      # so we can all ourselves anyway
      klass = self
      define_method theName do |quickylabel = nil, &block|
        klass.send :undef_method, theName
        require_relative thePath
        # the following call should not cause another registerControlClassProxy!!
        send(theName, quickylabel, &block)
      end
      private theName
    end

    # does NOT add the control for Qt !!!, but it does so for layouts ??
    # it returns the added control
    def addControl control, &block
      if control.widget?
        @all_widgets << control
      elsif control.layout?
        @qtc.layout = control.qtc
      end
      control.instance_eval(&block) if block
      control.postSetup
    end

  end # class Panel

  # forward definition
  class Layout < Panel
  end
end # Reform