module Reform

  class AbstractAction < Control

    private

    def initialize parent, qtc
      super
      if @qtc
        connect(@qtc, SIGNAL('triggered()'), self) do
          if instance_variable_defined?(:@whenTriggered)
#             tag "call whenTriggered #{@whenTriggered.inspect}"
            rfCallBlockBack(&@whenTriggered)
          else
            STDERR.puts "Unimplemented action handler for #{self.class} '#{objectName}:#{@qtc.text}'"
          end
        end
      end
    end

    # notice: these can no longer be queried....
    def enabler value = nil, &block
      DynamicAttribute.new(self, :enabled, TrueClass, value, &block)
    end

    def disabler value = nil, &block
      DynamicAttribute.new(self, :disabled, TrueClass, value, &block)
    end

    public
#     def self.contextsToUse
#       ActionContext
#     end

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
        @whenTriggered = block
        # connect(@qtc, SIGNAL('triggered()'), self) { rfCallBlockBack(&block) }
        # Like this, each time 'whenTriggered' is called Qt adds another callback!!!
      else
        @qtc.triggered
      end
    end #whenTriggered

    alias :whenClicked :whenTriggered
  end
end
