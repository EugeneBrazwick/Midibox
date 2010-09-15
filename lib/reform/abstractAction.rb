module Reform

  class AbstractAction < Control

    private

    # notice: these can no longer be queried....
    def enabler value = nil, &block
      DynamicAttribute.new(self, :enabled, value, &block)
    end

    def disabler value = nil, &block
      DynamicAttribute.new(self, :disabled, value, &block)
    end

    public
    def self.contextsToUse
      ActionContext
    end

    def action?
      true
    end

    def addTo parent, hash, &block
      parent.addAction self, hash, &block
    end

    def self.parent_qtc parent_control, parent_effective_qtc
      parent_control.effective_qtc_for_action
    end

    # with a block, connect the callback, without it call the event (no block need be connected)
    def whenTriggered &block
      if block
        connect(@qtc, SIGNAL('triggered()'), self) { rfCallBlockBack(&block) }
      else
        @qtc.triggered
      end
    end #whenTriggered

  end
end
