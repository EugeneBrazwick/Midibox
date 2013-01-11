
require_relative 'control'

module R::Qt
  ## This diverts from the Qt hierarchy!!!
  # I don't suppose people want to use ruby to load 50000 items in a scene 
  class GraphicsItem < Control
    include GraphicContext
  end

  Reform.createInstantiator __FILE__, GraphicsItem
end

