
# Copyright (c) 2010 Eugene Brazwick

module Reform

  class Separator < Control
    def self.contextsToUse
      ActionContext
    end

    def action?
      true
    end

    def addWidget2Parent parent_qtc, child_qtc
      parent_qtc.addSeparator
    end


  end

  createInstantiator File.basename(__FILE__, '.rb'), nil, Separator

end