
# Copyright (c) 2011 Eugene Brazwick

require_relative '../graphicseffect.rb'

module Reform
  class Blur < GraphicsEffect
    private
      define_setter Float, :blurRadius

      alias :radius :blurRadius

  end

  createInstantiator File.basename(__FILE__, '.rb'), Qt::GraphicsBlurEffect, Blur

end
