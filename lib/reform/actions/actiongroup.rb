
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative '../abstractAction'

  class ActionGroup < AbstractAction
    include ActionContext
    private

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

  end

  createInstantiator File.basename(__FILE__, '.rb'), Qt::ActionGroup, ActionGroup

end