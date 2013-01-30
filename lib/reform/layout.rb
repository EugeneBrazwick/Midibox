
require_relative 'context'

module R::Qt

  class Layout < Control
      include Reform::WidgetContext

    public # methods of Layout

      # override
      def parent= parent
	parent.addLayout self
      end # parent=

  end # class Layout

end # module R::Qt
