
module Reform

  require_relative '../graphicsitem'
  class Line < GraphicsItem
  private

    def from x, y = nil
#       tag "qtc.pen.color=#{@qtc.pen.color}"
#       tag "from, qtc.pen.color=#{@qtc.pen.color.red} #{@qtc.pen.color.green} #{@qtc.pen.color.blue}"
      line = @qtc.line
      if y
        line.p1 = Qt::PointF.new(x, y)
      else
        line.p1 = x
      end
      @qtc.line = line
    end

    def to x, y = nil
      line = @qtc.line
      line.p2 = y ? Qt::PointF.new(x, y) : x
      @qtc.line = line
    end

  public

    def self.new_qt_implementor(qt_implementor_class, parent, qparent)
      line = qt_implementor_class.new(0.0, 0.0, 100.0, 100.0, qparent)
      line.pen = parent.pen
      line
    end

  end # Line

  createInstantiator File.basename(__FILE__, '.rb'), Qt::GraphicsLineItem, Line

end # Reform