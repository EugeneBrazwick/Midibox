
require_relative '../graphicsitem'    

module R::Qt
  class GraphicsLineItem < GraphicsItem

    public # methods of GraphicsLineItem

      # override
      def enqueue_children queue = nil
	super
	if @pen
	  queue and queue.push @pen or yield @pen
	end
      end

      def pen_get; @pen; end

      attr_dynamic PointF, :from, :to
  end
  Reform.createInstantiator __FILE__, GraphicsLineItem
end # module R::Qt

if __FILE__ == $0
  require 'reform/app'
  Reform::app {
    canvas {
      size 320, 240
      scale 2.3
      scene {
	area 100
	rectangle rect: 100, stroke: :blue
	for i in 30.step(50, 10)
	  line from: [10, i], to: [90, i]
	end
      }
    }
  }
end
