
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

      @solidBrush = {}

      def self.solidBrush key
	@solidBrush[key] ||= Brush.new(Color.sym2color(key) || Brush::NoBrush)
      end

    public # methods of GraphicsItem

      # override
      def parent= parent
	parent.addGraphicsItem self
      end # addToParent

      def addGraphicsItem item
	item.qtparent = self
      end # addGraphicsItem

      ## :call-seq:
      #	  brush	-> current brush
      #	  brush :blue
      #	  brush QBrush
      #	  brush { initblock }
      #	  brush inithash: .... 
      def brush *args, &block
	arg0 = args[0]
	return brush_get unless arg0 || block
	self.brush = Brush.new(*args, &block)
	tag "#{self}.brush := #{brush_get}"
      end # brush

      alias :fill :brush
      alias :fillcolor :brush

  end # class GraphicsItem

  Reform.createInstantiator __FILE__, GraphicsItem
end

