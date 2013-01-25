
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

    ## :call-seq:
    #	  make_brush
    #
    # convert anything into a QBrush
      def make_brush *args, &block
	args = args[0] if args.length <= 1
	case args
	when Brush then args
	when false, :none, :nobrush, :no_brush then solidBrush :none
	when nil
	  if block
	    Brush.new(&block)
	  else
	    solidBrush :none
	  end
	when Hash then Brush.new args
	when String
	  if args[0, 7] == 'file://'
	    raise NotImplemtedError, "loading pixmaps for brushes"
	  else
	    Brush.new Color.new args
	  end
	when Array then Brush.new Color.new(*args)
	when Color then Brush.new args
	else Brush.new Color.new args
	end
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
	self.brush = case arg0
		     #when Symbol then make_brush(self, *args)
		     when Brush then arg0
		     when nil then Brush.new(&block)
		     else make_brush(*args)
		     end
      end # brush

      alias :fill :brush
      alias :fillcolor :brush

  end # class GraphicsItem

  Reform.createInstantiator __FILE__, GraphicsItem
end

