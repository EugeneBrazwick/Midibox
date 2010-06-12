
# Copyright (c) 2010 Eugene Brazwick

module Reform
  class ActionGroup < Control
    include ActionContext
    private

    public
    # override
    def self.contextsToUse
      ActionContext
    end

    def action?
      true
    end

    def addWidget2Parent parent_qtc, child_qtc
    end

    def self.parent_qtc control, qtc
      control.containing_form.qtc
    end

    def effective_qtc_for_action
      @qtc
    end

    def whenTriggered &block
      if block
        connect(@qtc, SIGNAL('triggered()'), self) { rfCallBlockBack(&block) }
      else
        @qtc.triggered
      end
    end #whenTriggered

  end

  createInstantiator File.basename(__FILE__, '.rb'), Qt::ActionGroup, ActionGroup

end