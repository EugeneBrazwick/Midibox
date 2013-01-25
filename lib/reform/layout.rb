
require_relative 'context'

module R::Qt

  class Layout < Control
      include Reform::WidgetContext

    public # methods of Layout

      # override
      def parent= parent
	parent.addLayout self
      end # parent=

      # override
      def children
	each_child.to_a # .tap{|c| tag "children->#{c.inspect}"}
      end # children

  end # class Layout

end # module R::Qt
