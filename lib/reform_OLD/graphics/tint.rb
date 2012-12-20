
# Copyright (c) 2011 Eugene Brazwick

require_relative '../graphicseffect.rb'

module Reform
  class Tint < GraphicsEffect
    private
      define_setter Qt::Color, :color
    public
      def color= value
#         tag "color:= #{value.inspect}"
        @qtc.color = value
        parent.qtc.opacity = value.alphaF
      end
  end

  createInstantiator File.basename(__FILE__, '.rb'), Qt::GraphicsColorizeEffect, Tint

end
