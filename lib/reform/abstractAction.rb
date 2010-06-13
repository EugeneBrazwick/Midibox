module Reform

  class AbstractAction < Control

    private

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

    def whenTriggered &block
      if block
        connect(@qtc, SIGNAL('triggered()'), self) { rfCallBlockBack(&block) }
      else
        @qtc.triggered
      end
    end #whenTriggered

  end
end
