
require_relative 'widget'

module R::Qt
  class GraphicsView < Widget 
    public #methods of GraphicsView
    
      def addScene scene
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
