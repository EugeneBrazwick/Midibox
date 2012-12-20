
module Reform

  require 'reform/model'

  class DelegateModel < AbstractModel
    private

    public

    def self.new_qt_implementor qt_implementor_class, parent, qt_parent
      qt_implementor_class.new(parent.containing_form.qtc)
    end

    def addTo parent, hash, &block
      parent.qtc.itemDelegate = @qtc
      setup(hash, &block)
      parent.added self
    end

     # If self is the class of the child, which qtc to use as parent
    def self.parent_qtc parent_control, parent_effective_qtc
      parent_effective_qtc
    end

  end

end