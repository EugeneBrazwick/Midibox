module Reform
  class Action < Control
    include MenuContext
    private

    define_simple_setter :text

    public
    def self.contextsToUse
      ActionContext
    end

    def action?
      true
    end

        # adding any control to any parent.  The default makes no relationships. It just initializes the control properly
    def addControl control, quickyhash = nil, &block
      raise unless control.menu?
      @qtc.menu = control.qtc
      super
    end

  end

  createInstantiator File.basename(__FILE__, '.rb'), Qt::Action, Action

end