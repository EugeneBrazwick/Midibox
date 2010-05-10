
# qtruby version of the AnalogClock example widget

module Reform

  class QAnalogClock < Qt::Widget
    private
    def initialize qparent
      super
#       resize 400, 400
#       tag "resize is UTTERLY ignored!!??"
      timer = Qt::Timer.new self
      connect(timer, SIGNAL('timeout()'), self) { update }
      timer.start 1000
      windowTitle = tr('Analog Clock')
    end

    Size = 500.0

    protected
     # causes misbehavior in paintEvent....
#     def showEvent *args
#       resize 400, 400
#     end

     #override
    def paintEvent *args
      hourHand = Qt::Polygon.new([Qt::Point.new(7, 8), Qt::Point.new(-7, 8), Qt::Point.new(0, -40)])
      minuteHand = Qt::Polygon.new([Qt::Point.new(7, 8), Qt::Point.new(-7, 8), Qt::Point.new(0, -70)])
      hourColor = Qt::Color.new 127, 0, 127
      minuteColor = Qt::Color.new 0, 127, 127, 191
      side = [width, height].min
      time = Qt::Time::currentTime
      painter = Qt::Painter.new self
      begin
        painter.renderHint = Qt::Painter::Antialiasing
        # set up the screen so topleft = -100,-100 and bottomright = 100,100
        painter.translate width / 2, height / 2
        painter.scale side / 200.0, side / 200.0
        painter.pen = Qt::NoPen # with no outline
        painter.brush = Qt::Brush.new(hourColor)
        painter.save
        begin
          painter.rotate 30.0 * (time.hour + time.minute / 60.0)
          painter.drawConvexPolygon hourHand
        ensure
          painter.restore
        end
        painter.pen = hourColor
        for i in 0...12 do
          painter.drawLine 88, 0, 96, 0
          painter.rotate 30.0
        end
        painter.pen = Qt::NoPen
        painter.brush = Qt::Brush.new(minuteColor)
        painter.save
        begin
          painter.rotate 6.0 * (time.minute + time.second / 60.0)
          painter.drawConvexPolygon minuteHand
        ensure
          painter.restore
        end
        painter.pen = minuteColor
        for j in 0...60 do
           painter.drawLine(92, 0, 96, 0) unless j % 5 == 0
           painter.rotate 6.0
        end
      ensure
        painter.end
      end
    end

    public
    # This is the way to go here!!! to ignore return Qt::Size.new(-1, -1)
    def sizeHint
      Qt::Size.new(Size.to_i, Size.to_i)
    end
  end # class QAnalogClock

  createInstantiator File.basename(__FILE__, '.rb'), QAnalogClock
end # Reform