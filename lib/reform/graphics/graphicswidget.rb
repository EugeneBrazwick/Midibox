
# Copyright (c) 2010 Eugene Brazwick


# Copyright (c) 2010 Eugene Brazwick

module Reform

  require 'reform/graphicsitem'

  class GraphicsWidget < GraphicsItem
    private

    public
      # return true to indicate we are a proper parent for subitems in a graphics layout
      def widget?
        true
      end
  end # class GraphicsWidget

  createInstantiator File.basename(__FILE__, '.rb'), Qt::GraphicsWidget, GraphicsWidget

end # module Reform