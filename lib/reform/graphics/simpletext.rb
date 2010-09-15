
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative '../graphicsitem'

  # the position is once more the center
  class SimpleText < GraphicsItem
  private

    # this text can contain newlines, resulting in a multiline item (left aligned, may be based on locale?)
    def text t = nil
      return @qtc.text unless t
      @qtc.text = t
    end

  public

  end # SimpleText

  createInstantiator File.basename(__FILE__, '.rb'), Qt::GraphicsSimpleTextItem, SimpleText
#   tag "test for Scene#circle"
#   raise ReformError, 'oh no' unless Scene.private_method_defined?(:circle)

end # Reform