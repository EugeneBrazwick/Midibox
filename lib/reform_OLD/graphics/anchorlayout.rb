

# Copyright (c) 2010 Eugene Brazwick

module Reform

  require 'reform/layout'

  class AnchorLayout < Layout
    private


    public

  end # class AnchorLayout

  createInstantiator File.basename(__FILE__, '.rb'), Qt::GraphicsAnchorLayout, AnchorLayout

end # Reform