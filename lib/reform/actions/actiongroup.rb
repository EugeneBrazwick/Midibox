
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative '../abstractAction'

  class ActionGroup < AbstractAction
    include ActionContext
    private

    def initialize parent, qtc
      super
      @all_children = []
    end

    # similar to Frame
    def added control
      @all_children << control
      control.containing_frame = self
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
      @all_children.each do |action|
        @containing_frame.qtc.addAction(action.qtc)
      end
    end
  end

  createInstantiator File.basename(__FILE__, '.rb'), Qt::ActionGroup, ActionGroup

end