
=begin

Just do it like this:

=end

require 'reform/graphics/rectangle'

# use the proper namespace
module Reform

  # define the controller class
  # Let's inherit from Rectangle since apart from drawing there is not much difference.
  class CrossGraphic < Rectangle
  end

  # define the Qt class, inherit from the corresponding Qt class
  class QCrossGraphic < QGraphicsRectItem
    public
      # override the paint method.  For details see the documentation for qt on http://doc.qt.nokia.com/4.7/
      def paint painter, option, widget
        # paint a cross.
        painter.pen = Qt::Pen.new(Qt::Brush.new(Qt::Color.new(160, 160, 160)), 20.0,
                                  Qt::SolidLine, Qt::RoundCap)
        painter.drawLine(0, 5, 60, 65)
        painter.drawLine(60, 5, 0, 65)
      end

  end

#         createInstantiator 'cross', QCrossGraphic, CrossGraphic               BAD IDEA.... Wrong method.
# createInstantiator lacks 'what' we are declaring, since this is taken from the directory of the file.
# That would be OK if we had a file 'cross.rb' parked in the 'graphics' subdirectory.

# So, to activate it use:
  registerKlass GraphicsItem, :cross, QCrossGraphic, CrossGraphic
  # registerKlass(What, Name, Qt-Class, Reform-Class)

end # Reform

=begin
Reform::app {
  form {
    canvas {
      area 0, 0, 100, 100
      scale 3
      background lightGray
      cross color: black
    }
  }
}

=====================================================================================================================
=====================================================================================================================

  That completed our first attempt.

  Say we want a color parameter.

  We can do that right away:

=end

module Reform # open it again

  class CrossGraphic < Rectangle
    private
      define_setter Qt::Color, :color
      # voila, a color parameter
  end

  # Easy enough, you controller you!
  # the Qt class must do a lot more:
  class QCrossGraphic < QGraphicsRectItem
    private
      def initialize parent
        super
        # setup the default color, in case the user does not specify it
        @color = Qt::Brush.new(Qt::Color.new(160, 160, 160))
      end

    public
      # create an assigner to handle data passed to us from CrossGraphic
      def color= col
        @color = Graphical::make_qtbrush_with_parent self, col
        update # force a repaint
      end

      # redo the paint method, to use the @color (which is secretly a Qt::Brush!)
      def paint painter, option, widget
        # paint a cross.
        painter.pen = Qt::Pen.new(@color, 20.0, Qt::SolidLine, Qt::RoundCap)
        # This can be improved by creating the pen with the color.
        # Now everyy paint event causes a new pen to be created.
        painter.drawLine(0, 5, 60, 65)
        painter.drawLine(60, 5, 0, 65)
      end
  end
end # Reform

=begin
Reform::app {
  form {
    canvas {
      area 0, 0, 100, 100
      scale 3
      background lightGray
      cross color: black
      # Much better than 'drawX 0'
    }
  }
}

=====================================================================================================================
=====================================================================================================================

adding 'weight' for the pen is now easy:
=end


module Reform # open it again

  class CrossGraphic < Rectangle
    private
      define_setter Qt::Color, :color
      define_setter Float, :weight
  end

  class QCrossGraphic < QGraphicsRectItem
    private
      def initialize parent
        super
        @color = Qt::Brush.new(Qt::Color.new(160, 160, 160))
        @weight = 20.0
      end

      def newpen
        @pen = Qt::Pen.new(@color, @weight, Qt::SolidLine, Qt::RoundCap)
        update # force a repaint
      end

    public
      def color= col
        @color = Graphical::make_qtbrush_with_parent self, col
        newpen
      end

      def weight= w
        @weight = w
        newpen
      end

      def paint painter, option, widget
        painter.pen = @pen
        # let's obey 'rect'
        r = rect
        painter.drawLine(r.topLeft, r.bottomRight)
        painter.drawLine(r.topRight, r.bottomLeft)
      end
  end
end # Reform

Reform::app {
  form {
    define {
      canvas_params parameters {
        area 0, 0, 100, 100
        scale 2
        background lightGray
      }
    }
    hbox {
      canvas {
        parameters :canvas_params
        cross color: 160, weight: 20, geo: [0, 5, 60]
        cross color: black, weight: 10, geo: [30, 20, 60]
        cross color: white, weight: 2, geo: [20, 38, 60]
      }
      canvas {
        parameters :canvas_params
        for i in 0...20
          cross color: 200 - i * 10, weight: (20 - i) * 2.0, geo: [i, i / 2.0, 70.0]
        end
      }
      canvas {
        parameters :canvas_params
        70.times do
          cross color: rand(256), weight: 30.0 * rand, geo: [rand(100), rand(100), 100]
        end
      }
    }
  }
}
