
module Reform

  class Menu < Control
    include ActionContext

    private
    define_simple_setter :title
    alias :text :title

    public
    def self.contextsToUse
      MenuContext
    end

    def menu?
      true
    end

    # override
    def addControl control, quickyhash = nil, &block
      raise unless control.action?
      addWidget control, control.qtc
      super
    end

    # ignore the parent
    def self.new_qt_implementor qt_implementor_class, parent, qt_parent
      qt_implementor_class.new
    end

    def registerName aName, aControl
      containing_form.registerName(aName, aControl)
    end

    def self.parent_qtc control, qtc
    end

  end

  createInstantiator File.basename(__FILE__, '.rb'), Qt::Menu, Menu

end