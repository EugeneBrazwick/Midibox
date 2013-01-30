
require_relative '../control'
require_relative '../context'

module R::Qt
  ## Note that our scene diverts from the Qt classtree!
  class GraphicsScene < Control
      include Reform::GraphicContext

    public # methods of GraphicsScene

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
