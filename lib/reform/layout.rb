
require_relative 'context'
require_relative 'layoutable'

module R::Qt

  class Layout < Control
      include Reform::WidgetContext
      include Able

    public # methods of Layout

      # override
      def parent= parent
	parent.addLayout self
      end # parent=

  end # class Layout

end # module R::Qt
