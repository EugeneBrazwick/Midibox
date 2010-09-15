
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative '../graphicsitem'

  # the position is once more the center
  class GraphicText < GraphicsItem
  private

    def text t = nil
      return @qtc.text unless t
      @qtc.text = t
    end

    def textWidth w = nil
      return @qtc.textWidth unless w
      @qtc.textWidth = w
    end

  public

  end # GraphicText

  createInstantiator File.basename(__FILE__, '.rb'), Qt::GraphicsTextItem, Graphictext

end # Reform