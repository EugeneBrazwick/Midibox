
require_relative '../context'
require_relative '_layoutable'

module R::Qt

  class Layout < Control
      include Reform::WidgetContext
      include Able

      @@sizeConstraints = nil

    public # methods of Layout

      # override
      def parent= parent
	parent.addLayout self
      end # parent=

      attr_dynamic Symbol, :sizeConstraint
  end # class Layout

end # module R::Qt
