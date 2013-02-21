
require_relative 'widget'
require 'forwardable'

module R::Qt
  class GraphicsView < AbstractScrollArea 
      include Reform::GraphicContext
      extend Forwardable

    private #methods of GraphicsView

      def_delegators :infused_scene!, :background, :backgroundBrush, :brush,
				      :area, :sceneRect,
				      :addItem, :addGraphicsItem

      def infused_scene!
	unless @infused_scene
	  require_relative 'graphicsscene'  # do NOT use the link!!!
	  scene
	  raise Reform::Error, "broken scenery" unless @infused_scene
	end
	@infused_scene
      end

    public #methods of GraphicsView
   
      def scale_get; @scale; end

      def addScene scene
	@infused_scene = scene
	scene.qtparent = self
	self.scene = scene
      end

      attr_dynamic SizeF, :scale
  end

  # req. for a plugin:
  Reform.createInstantiator __FILE__, GraphicsView
end

if __FILE__ == $0
  require 'reform/app'
  Reform.app {
    canvas {
    }
  }
end
