
require_relative 'control'
require_relative 'context'

module R::Qt

  class Rectangle
  end

  ## This diverts from the Qt hierarchy!!!
  # I don't suppose people want to use ruby to load 50000 items in a scene 
  class GraphicsItem < Control
      include Reform::GraphicContext

    public # methods of GraphicsItem

      # override
      def addToParent parent
	parent.addGraphicsItem self
      end # addToParent

      def addGraphicsItem item
	item.parent = self
      end # addGraphicsItem
  end # class GraphicsItem

  Reform.createInstantiator __FILE__, GraphicsItem
end

