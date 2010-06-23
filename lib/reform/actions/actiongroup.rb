
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative '../abstractAction'

  class ActionGroup < AbstractAction
    include ActionContext
    private

    # similar to Frame
    def added control
      control.parent = self
    end

    public

    def self.parent_qtc control, qtc
      control.containing_form.qtc
    end

    def addTo parent, hash, &block
      setup(hash, &block)
      parent.added self
    end

    def effective_qtc_for_action
      @qtc
    end

    def postSetup
      children.each do |action|
        parent.qtc.addAction(action.qtc)
      end
    end
  end

  createInstantiator File.basename(__FILE__, '.rb'), Qt::ActionGroup, ActionGroup

end