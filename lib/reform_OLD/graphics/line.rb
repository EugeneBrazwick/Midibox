
module Reform

  require 'reform/graphicsitem'

  class Line < GraphicsItem
  private

    define_setters Qt::PointF, :from, :to

=begin ORG
    def from x, y = nil
#       tag "qtc.pen.color=#{@qtc.pen.color}"
#       tag "from, qtc.pen.color=#{@qtc.pen.color.red} #{@qtc.pen.color.green} #{@qtc.pen.color.blue}"
      x, y = x if Array === x
      line = @qtc.line
      if y
        line.p1 = Qt::PointF.new(x, y)
      else
        line.p1 = x
      end
      @qtc.line = line
    end

    def to x, y = nil
      x, y = x if Array === x
      line = @qtc.line
      line.p2 = y ? Qt::PointF.new(x, y) : x
      @qtc.line = line
    end
=end

  public

    def self.new_qt_implementor(qt_implementor_class, parent, qparent)
      qt_implementor_class.new(0.0, 0.0, 100.0, 100.0, qparent)
#       line.pen = parent.pen
#       line
    end

  end # Line

  class QGraphicsLineItem < Qt::GraphicsLineItem
    include QGraphicsItemHackContext

      def brush= b; end
      def font= f; end

      def from= x, y = nil
        l = line
        l.p1 = Qt::PointF === x ? x : Qt::PointF.new(x, y || x)
        self.line = l
      end

      def to= x, y = nil
        l = line
        l.p2 = Qt::PointF === x ? x : Qt::PointF.new(x, y || x)
        self.line = l
      end
  end

  createInstantiator File.basename(__FILE__, '.rb'), QGraphicsLineItem, Line

end # Reform