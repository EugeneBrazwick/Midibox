
module Reform

  require_relative '../graphicsitem'

  class SimpleText < GraphicsItem
  private

    # override. Position of the center(!)
    def position x, y = nil
      x, y = x if y.nil?
      @qtc.setPos x, y
    end

    def text val
      @qtc.text = val
    end

  public

    # same as Circle.  Share code ? FIXME
    def self.new_qt_implementor(qt_implementor_class, parent, qparent)
      t = qt_implementor_class.new(qparent)
      t.pen, t.brush = parent.pen, parent.brush
      t
    end

  end # SimpleText

  createInstantiator File.basename(__FILE__, '.rb'), Qt::GraphicsSimpleTextItem, SimpleText

end # Reform