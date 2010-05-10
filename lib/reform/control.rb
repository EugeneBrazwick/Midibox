
module Reform

=begin rdoc
  Control instances are qtruby wrappers around the Qt elements.
  We extend QObject (Qt::Object) itself to enable slots and signals
=end
  class Control < Qt::Object
    private

    # create a new Control, using the panel as 'owner', and qtc as the wrapped Qt::Widget
    def initialize panel, qtc
      super()
      @panel, @form, @qtc, @has_pos = panel, panel.form, qtc, false
    end

     # size QSize or size w,h, without args it returns qtc.size
    def size w = nil, h = nil
      return parent_qtc_to_use.size unless w
      if h
        @requested_size = w, h
        parent_qtc_to_use.resize w, h
      else
        @requested_size = w, w
        parent_qtc_to_use.resize w, w
      end
    end

    # geometry, set geo or return it.
    def geometry x = nil, y = nil, w = nil, h = nil
      return parent_qtc_to_use.geometry unless x or w
      @requested_size = w, h
      if x or y
        @has_pos = true
        parent_qtc_to_use.setGeometry x, y, w, h
      else
        parent_qtc_to_use.resize w, h
      end
    end

    # define a simple set method for each element passed, forwarding it to qtc.
    def self.define_simple_setter *list
      list.each do |name|
        define_method name do |value|
          @qtc.send(name.to_s + '=', value)
        end
      end
    end

    public
    # the owner == parent widget (a Reform::Panel)
    attr :panel

    # the owner form.
    attr :form

    # Qt control that is wrapped
    attr :qtc

    # tuple w,h   as set in last call of setSize/setGeometry
    attr :requested_size

    def has_pos?
      @has_pos
    end

    def when_resized &block
      return @when_resized unless block
      @when_resized = block
    end

    # normally the Qt implementor, but for layouts we add subcontrols to the
    # layouts owner. In other words, the result must be a Qt::Widget in all cases
    # which does not hold for all Controls.@qtc values.
    # Examples are Layout, Action and RSignalMapper.
    # Also, some subcontrols need 'nil' is their parent and this can be arranged
    # like this as well
    def parent_qtc_to_use
      @qtc
    end

    # this callback is called after the 'block' initialization. Or even without a block,
    # when the control is added to the parent and should have been setup.
    # can be used for postProc. Example: initialization parameters are stored and
    # executed in one go.  Note that postSetup should return self!
    def postSetup
      self
    end

    # parent can be nil, but even then....
    # example, according to qt4 manual 'new Qt::GraphicsEllipseItem()' should be legal.
    # But qtruby thinks otherwise!
    def self.new_qt_implementor qt_implementor_class, qt_parent
      qt_implementor_class.new qt_parent
    end

    # widget -> bool.  Returns true if the control is a widget
    def widget?
    end

    # layout -> bool. Returns true if the control is a layout
    def layout?
    end
  end
end # Reform