
require_relative 'control'
require_relative 'context'

module R::Qt

  class Rectangle
  end

  ## This diverts from the Qt hierarchy!!!
  # I don't suppose people want to use ruby to load 50000 items in a scene 
  class GraphicsItem < NoQtControl
      include Reform::GraphicContext

    private # methods of GraphicsItem

    public # methods of GraphicsItem

      # override
      def parent= parent
	parent.addGraphicsItem self
      end # parent=

      def addGraphicsItem item
	item.qtparent = self
      end # addGraphicsItem

      ## :call-seq:
      #	  brush	-> current brush
      #	  brush :blue
      #	  brush QBrush
      #	  brush { initblock }
      #	  brush inithash: .... 
      #
      #	PROBLEM:  getting a brush always makes a copy,
      #	and setting it too, actually.
      #
      #	Hence the VALUE returned by brush differs from the one last set.
      #	Now:
      #	    self.brush = Brush.new(self, *args, &block)
      # may call back en call self->setBrush().  For example if there is a block or a hash
      # containing 'connector'.
      #
      # This example shows that connector should NOT immediately fetch the required data.
      # However, my solution is now to revert the assigning of the brush to the brush constructor
      def brush *args, &block
	arg0 = args[0]
	return brush_get unless arg0 || block
	tag "calling Brush.new with parent #{self}"
	Brush.new(self, *args, &block)
      end # brush

      alias :fill :brush
      alias :fillcolor :brush

  end # class GraphicsItem

  Reform.createInstantiator __FILE__, GraphicsItem
end

