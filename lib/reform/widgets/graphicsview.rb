
require_relative 'widget'
require 'forwardable'

module R::Qt
  class GraphicsView < Widget 
      include Reform::GraphicContext
      extend Forwardable

    private #methods of GraphicsView

      def_delegators :infused_scene!, :background, :backgroundBrush, :brush,
				      :area, :sceneRect,
				      :addItem, :addGraphicsItem

      def infused_scene!
	unless @infused_scene
	  require_relative 'scene'
	  scene
	  raise Reform::Error, "broken scenery" unless @infused_scene
	end
	@infused_scene
      end

    public #methods of GraphicsView
    
      def addScene scene
	@infused_scene = scene
	scene.qtparent = self
	self.scene = scene
      end
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
