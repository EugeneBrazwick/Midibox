
module Reform

  require_relative 'model'

  class DelegateModel
    include Model

    def self.new_qt_implementor qt_implementor_class, parent, qt_parent
      qt_implementor_class.new(parent.containing_form)
    end

        # override
    def addWidget2Parent parent_qtc, child_qtc
      tag "#{parent_qtc}.itemDelegate := #{child_qtc}"
      parent_qtc.itemDelegate = child_qtc
    end

  end

end