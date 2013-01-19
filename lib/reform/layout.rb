
require_relative 'context'

module R::Qt

  class Layout < Control
      include Reform::WidgetContext

    public # methods of Layout

      def parent= parent
	parent.addLayout self
      end # parent=

      def children
	each_child.to_a
      end
  end # class Layout

end # module R::Qt
