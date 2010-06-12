
# Copyright (c) 2010 Eugene Brazwick

module Reform
  class Action < Control
    include MenuContext
    private

    def initialize parent, qtc
      super
      connect(@qtc, SIGNAL('triggered()')) do
        rfRescue do
          if instance_variable_defined(:@value) && cid = connector && model = effectiveModel
            model.apply_setter cid, @value
          end
        end
      end
    end

    define_simple_setter :text, :checkable
    #, :shortcut

    # it is possible that an Qt::Enum value is passed. pe: Qt::KeySequence::Quit
    def shortcut x
#       tag "setShortcut(#{x.class} #{x})"
      x = Qt::KeySequence.new(x) if x.is_a?(Qt::Enum)
      @qtc.shortcut = x
    end

    def checked v
      @qtc.checkable = true
      @qtc.checked = v
    end

    def value v = nil
      return instance_variable_defined(:@value) && @value unless v
      @value = v
    end

    public
    def self.contextsToUse
      ActionContext
    end

    def action?
      true
    end

    def addWidget2Parent parent_qtc, child_qtc
      parent_qtc.addAction child_qtc
    end

        # adding any control to any parent.  The default makes no relationships. It just initializes the control properly
    def addControl control, quickyhash = nil, &block
      raise unless control.menu?
      @qtc.menu = control.qtc
      super
    end

    def self.parent_qtc parent_control, parent_effective_qtc
      parent_control.effective_qtc_for_action
    end

    def whenTriggered &block
      if block
        connect(@qtc, SIGNAL('triggered()'), self) { rfCallBlockBack(&block) }
      else
        @qtc.triggered
      end
    end #whenTriggered

  end

  createInstantiator File.basename(__FILE__, '.rb'), Qt::Action, Action

end