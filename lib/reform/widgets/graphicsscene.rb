
require_relative '../control'
require_relative '../context'

module R::Qt
  ## Note that our scene diverts from the Qt classtree!
  class GraphicsScene < Control

      #tag "Scanning class GraphicsScene, caller = #{caller.join("\n")}"
    
      include Reform::GraphicContext

    public # methods of GraphicsScene

      # override
      def parent= par
	par.addScene self
      end

      # override
      def addObject child
	TypeError.raise 'can only add GraphicsItems to a GraphicsScene'
      end

      # override
      def children
	each_child.to_a
      end

      def backgroundBrush_get; @brush; end

      def backgroundBrush *args, &block
	return backgroundBrush_get if args.empty?
	Brush.new self, *args, &block
      end

      # tag "setting up 'title' attr_dynamic"
      attr_dynamic RectF, :sceneRect

      alias background backgroundBrush
      alias brush= backgroundBrush=
      alias addGraphicsItem addItem
      alias area sceneRect

      #tag "Done scanning class GraphicsScene"
  end # class GraphicsScene

  Reform.createInstantiator __FILE__, GraphicsScene
end # module R::Qt

if __FILE__ == $0
  require 'reform/app'
  Reform::app {
    canvas {
      scene {
      }
    }
  }
end
