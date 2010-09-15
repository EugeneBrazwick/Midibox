
module Reform

  require 'reform/controls/widget'

  class ShadeWidget < Widget
  private
    define_simple_setter :shadetype
  end

=begin
   See Qt::SourceDir/demos/shared/hoverpoints.cpp/h

   helperclass that allows a user to create a function using controlpoints.
   To set the initial function use 'points='
   To read the controlpoints use 'points'. This is an array of Qt::PointF items.
   It is possible to lock a point to the left, right, bottom or top of the
   window by calling setPointLock.

   Creating it for a widget takes over control so the user can:

      add a controlpoint by clicking in the window
      remove one by rightclicking
      move one by dragging

    the touchinterface code has not been tested by me.

  When the widget is updated the points are drawn over the normal content.

  If editable is false you can still move the points, but not add or delete them
  If enabled is false, the points can not be altered.
=end
  class HoverPoints < Qt::Object

  #    enum PointShape {
#           CircleShape = 0     use :circle
#           RectangleShape = 1  use :rectangle, or anything else but :circle (for that matter)
  #     };


  #     enum LockType {

  # which one  to use  depends on the sortType.
          LockToLeft   = 0x01
          LockToRight  = 0x02
          LockToTop    = 0x04
          LockToBottom = 0x08
  #     };

  #     enum SortType {
#           NoSort = 0          nil
#           XSort = 1           :x
#           YSort = 2    :y
  #     };

  #     enum ConnectionType {
#           NoConnection = 0     nil
#                LineConnection = 1   :line     (anything but nil or :curve)
#           CurveConnection = 2         :curve
  #     };

    private
      def initialize widget, shape
        super(widget)
        # widget is therefore also the same as 'parent'.
        @widget, @shape = widget, shape
        widget.installEventFilter(self) # calls back 'eventFilter'
        widget.setAttribute(Qt::WA_AcceptTouchEvents)
        @connectionType = :curve
        @sortType = nil
        # array of 'active' points, that you can add, delete and move:
        # IMPORTANT: it must be filled with Qt::PointF and never Qt::Point!
        @points_ex = []
        # for each point there is lockinfo as well:
        @locks = []
        # Size of the points
        @pointSize = Qt::SizeF.new(11, 11)
        # represents touchevent:
        @fingerPointMapping = {}
        @pointPen = Qt::Pen.new(Qt::Brush.new(Qt::Color.new(255, 255, 255, 191)), 1)
        @pointBrush = Qt::Brush.new(Qt::Color.new(191, 191, 191, 127))
        # pen for the curves between the points:
        @connectionPen = Qt::Pen.new(Qt::Brush.new(Qt::Color.new(255, 255, 255, 127)), 2)
        # set for mouse dragging, to the index of the dragged point:
        @currentIndex = nil
        @editable = @enabled = true
        # can be override, normally widget.rect is the boundingRect
        @boundingRect = nil # = Qt::RectF.new
        connect(self, SIGNAL('pointsChanged(const QPolygonF &)')) { @widget.update }
      end

      def self.bound_point point, bounds, lock
#         tag "bound_point((#{point.x},#{point.y}), #{bounds.inspect}, lock=#{lock})"
#         p = Qt::PointF.new(point.x, point.y)
        left, right, top, bottom = bounds.left, bounds.right, bounds.top, bounds.bottom
#         tag "#{point.x} < #{left} || #{lock} & #{HoverPoints::LockToLeft} ???"
        Qt::PointF.new(if point.x < left || (lock & HoverPoints::LockToLeft) != 0
#                          tag "px := left #{left}"
                         left
                       elsif point.x > right || (lock & HoverPoints::LockToRight) != 0
#                          tag "px := right #{right}"
                         right
                       else
                         point.x
                       end,
                       if point.y < top || (lock & HoverPoints::LockToTop) != 0
#                          tag "py := top #{top}"
                         top
                       elsif point.y > bottom || (lock & HoverPoints::LockToBottom) != 0
#                          tag "py := bottom #{bottom}"
                         bottom
                       else
                         point.y
                       end)
#         tag "bound_point(#{point.inspect}, bounds=#{bounds.inspect}, lock=#{lock}) -> #{p.inspect}"
#         p
      end

    public

      # Qt callback
      def eventFilter object, event
        if object == @widget && @enabled
          case event.type
          when Qt::Event::MouseButtonPress
#             tag "MouseButtonPress"
            return true unless @fingerPointMapping.empty?
            clickPos = Qt::PointF.new(event.pos.x, event.pos.y)
            index = nil
            # which point is the mouse in?
            @points_ex.each_with_index do |p, i|
              # for mapping
              path = Qt::PainterPath.new
              brct = pointBoundingRect(p)
              if @shape == :circle
                path.addEllipse brct
              else
                path.addRect brct
              end
#               tag "Does #{brct.inspect} contain clickPos #{clickPos.inspect}?"
              if path.contains(clickPos)
                index = i
                break
              end
            end # each
            case event.button
            when Qt::LeftButton
#               tag "LeftButton"
              if index
                @currentIndex = index
              else
                return false unless @editable
#                 tag "no point clicked, can we add one?"
                pos = 0
                case @sortType
                when :x
                  @points_ex.each_with_index do |p, i|
                    if p.x > clickPos.x
                      pos = i
                      break
                    end
                  end
                when :y
                  @points_ex.each_with_index do |p, i|
                    if p.y > clickPos.y
                      pos = i
                      break
                    end
                  end
                end
#                 tag "Insert clickPos #{clickPos.inspect} at pos #{pos}"
                @points_ex.insert(pos, clickPos)
                @locks.insert(pos, 0)
#                 tag "setting currentIndex to #{pos}"
                @currentIndex = pos
                firePointChange
              end
              return true
            when Qt::RightButton
#               tag "RightButton deletes a point, unless it is locked, index=#{index}"
              if index && @editable
                if @locks[index] == 0
#                   tag "delete #{index}"
                  @locks.delete_at(index)
                  @points_ex.delete_at(index)
#                   tag "points is now #{@points_ex.inspect}"
                  firePointChange
                end
                return true
              end
            end
          when Qt::Event::MouseButtonRelease
#             tag "MouseButtonRelease"
            return true unless @fingerPointMapping.empty?
            @currentIndex = nil
          when Qt::Event::MouseMove
#             tag "MouseMove, fingerPointMapping=#{@fingerPointMapping.inspect}"
            return true unless @fingerPointMapping.empty?
#             tag "calling movePoint(clickPos), if #@currentIndex is set"
            movePoint(@currentIndex, Qt::PointF.new(event.pos.x, event.pos.y)) if @currentIndex
          when Qt::Event::TouchBegin, Qt::Event::TouchUpdate
            points = event.touchPoints
            pointSize = [@pointSize.width, @pointSize.height].max
            points.each do |touchPoint|
              id = touchPoint.id
              case touchPoint.state
              when Qt::TouchPointPressed
                activePoints = @fingerPointMapping.values
                activePoint = -1
                distance = -1.0
                pointsCount = @points_ex.length
                activePointCount = activePoints.length
                if pointsCount == 2 && activePointCount == 1
                  activePoint = activePoints.contains?(0) ? 1 : 0
                else
                  (0...pointsCount).each do |i|
                    next if activePoints.contains?(i)
                    d = Qt::LineF.new(touchPoint.pos, @points_ex[i]).length
                    if distance < 0 && d < 12 * pointSize || d < distance
                      distance = d
                      activePoint = i
                    end
                  end
                end
                unless activePoint == 1
                  @fingerPointMapping[touchPoint.id] = activePoint
                  movePoint(activePoint, touchPoint.pos)
                end
              when Qt::TouchPointReleased
                movePoint(@fingerPointMapping.keys.find_index(id), touchPoint.pos)
                @fingerPointMapping.delete(id)
              when Qt::TouchPointMoved
                movePoint(@fingerPointMapping.keys.find_index(id), touchPoint.pos) if @fingerPointMapping[id]
              end
            end # each
            if @fingerPointMapping.empty?
              event.ignore
              return false
            end
            return true
          when Qt::Event::TouchEnd
            if @fingerPointMapping.empty?
              event.ignore
              return false
            end
            return true
          when Qt::Event::Resize
#             return false if event.oldSize.width <= 0 || event.oldSize.height <= 0
#             oldSize = if event.oldSize.width <= 0 then InitSize else event.oldSize end
#             tag "cope with RESIZE from #{event.oldSize.inspect} to #{event.size.inspect}"
            maxx, maxy = 0.0, 0.0
            @points_ex.each do |p|
              maxx = p.x if p.x > maxx
              maxy = p.y if p.y > maxy
            end
            stretch_x = maxx == 0.0 ? event.size.width.to_f : event.size.width.to_f / maxx
            stretch_y = maxy == 0.0 ? event.size.height.to_f : event.size.height.to_f / maxy
#             event.oldSize.height.to_f
#             tag "stretch = #{stretch_x},#{stretch_y}"
            @points_ex.each_with_index do |p, i|
              movePoint(i, Qt::PointF.new(p.x * stretch_x, p.y * stretch_y), false)
            end
            firePointChange
#             tag "DONE RESIZE"
          when Qt::Event::Paint
#             tag "Qt::Event::Paint"
            that_widget = @widget
            @widget = nil
            $qApp.sendEvent(object, event)
            @widget = that_widget
            paintPoints
#             tag "did Qt::Event::Paint"
            return true
          end
        end # if enabled etc...
        false
      end   # eventFilter

      def paintPoints
        Painter.new(@widget) do |p|
          p.setRenderHint(Qt::Painter::Antialiasing)
          if @connectionPen.style != Qt::NoPen && @connectionType && !@points_ex.empty?
#             tag "paintPoints: #{@points_ex.inspect}"
            p.pen = @connectionPen
            if @connectionType == :curve
              path = Qt::PainterPath.new
              path.moveTo(@points_ex[0])
              (1...@points_ex.length).each do |i|
                p1 = @points_ex[i - 1]
                p2 = @points_ex[i]
                distance = p2.x - p1.x
                path.cubicTo(p1.x + distance / 2, p1.y,
                            p1.x + distance / 2, p2.y,
                            p2.x, p2.y)
              end
              p.drawPath(path)
            else
              p.drawPolyline(@points_ex)
            end
          end
          p.pen = @pointPen
          p.brush = @pointBrush
          @points_ex.each do |pt|
            bounds = pointBoundingRect(pt)
            if @shape == :circle
              p.drawEllipse bounds
            else
              p.drawRect bounds
            end
          end
        end
      end # paintPoints

      # the boundingRect can be forced.
      def boundingRect
        @boundingRect || @widget.rect
      end

      attr_accessor :pointSize, :sortType, :connectionType, :editable
      attr_writer :boundingRect

      attr :points

      def points= points
        @fingerPointMapping = {} unless @points_ex.length == points.length
        @points_ex = []
        bdr = boundingRect
#         tag "bdr = #{bdr.inspect}"
        points.each do |p|
          @points_ex << HoverPoints.bound_point(p, bdr, 0)
        end
        @locks = []
        @locks.fill(0, 0...@points_ex.length) unless @points_ex.empty?
      end

      attr_writer :connectionPen

      def shapePen= pen
        @pointPen = pen
      end

      def shapeBrush= brush
        @pointBrush = brush
      end

      def setPointLock pos, lock
        @locks[pos] = lock
      end

      slots 'enabled=(bool)', 'disabled=(bool)'

      def enabled= value
        unless @enabled == value
          @enabled = value
          @widget.update
        end
      end

      def disabled= value
        self.enabled = !value
      end

      signals 'pointsChanged(const QPolygonF &)'

      # x is supposedly the pixel value and should match the sortType, otherwise
      # the contents may not be a proper function.
      # So if sortType == :x, then x is input and y output,
      # and for sortType :y the result is x.
      def valueAt x
        prevpt = nil
        case @sortType
        when :x
          pts.each do |p|
            if prevpt && prevpt.x <= x && p.x >= x
              return p.x == prevpt.x ? p.y : prevpt.y + (x - prevpt.x) / (p.x - prevpt.x) * (p.y - prevpt.y)
              # returning x2 is useless, since it is bound to be equal to x.
            end
            prevpt = p
          end
        when :y
          pts.each do |p|
            if prevpt && prevpt.y <= y && p.y >= y
              return p.y == prevpt.y ? p.x : prevpt.x + (y - prevpt.y) / (p.y - prevpt.y) * (p.x - prevpt.x)
            end
            prevpt = p
          end
        end
      end

      alias [] valueAt

    private

      def firePointChange
#         tag "firePointChange"
        if @sortType
          oldCurrent = Qt::PointF.new
          oldCurrent = @points_ex[@currentIndex] if @currentIndex
          if @sortType == :x
            @points_ex.sort! { |p1, p2| p1.x <=> p2.x }
          else
            @points_ex.sort! { |p1, p2| p1.y <=> p2.y }
          end
          if @currentIndex
            @points_ex.each_with_index do |p, i|
              if p == oldCurrent
                @currentIndex = i
                break
              end
            end
          end
        end
        pointsChanged(@points_ex)
#         tag "did firePointChange"
      end # firePointChange

      # returns the bounding box of one of the active points on the curve:
      def pointBoundingRect p
        w, h = @pointSize.width, @pointSize.height
        Qt::RectF.new(p.x - w / 2, p.y - h / 2, w, h)
      end

      def movePoint index, point, emitUpdate = true
#         tag "movePoint(#{index}, #{point.inspect}, #{emitUpdate})"
        @points_ex[index] = HoverPoints.bound_point(point, boundingRect, @locks[index]) #.tap{|p| tag "pts[#{index}] := #{p.inspect}" }
        firePointChange if emitUpdate
      end

  end # class Hoverpoints

  require 'reform/painter'

=begin
  This widget uses the hoverpoint interface to display a vertical gradient for 1 of the 4
  primary colors (red, green, blue and alpha).

  However the :alpha version can be abused to display any vertical gradient (call gradientStops= for that)
  The exported data is caught through 'colorAt'. This returns the literal rgb value the user chose
  through setting the control points.
  However, this always uses linear connections, so it may not be exact (since it uses the :curve type)
=end
  class QShadeWidget < QWidget

    InitSize = Qt::Size.new(150, 40)

    private
      def initialize parent, type = :alpha
        super(parent)
        # can be :alpha, :red, :blue or :green
        @shade_type = nil
        @shade = nil
        @alpha_gradient =  Qt::LinearGradient.new(0, 0, 0, 0)
        # using sizeHint is weird? It seems to add 0,0 two times.
        points = [Qt::PointF.new(0, InitSize.height), Qt::PointF.new(InitSize.width, 0)]
#         tag "INITIAL POINTS: #{points.inspect}"
        @hoverPoints = HoverPoints.new(self, :circle)
        @hoverPoints.points = points
        @hoverPoints.setPointLock(0, HoverPoints::LockToLeft)
        @hoverPoints.setPointLock(1, HoverPoints::LockToRight)
        @hoverPoints.sortType = :x
        self.shadetype = type
        connect(@hoverPoints, SIGNAL('pointsChanged(const QPolygonF &)'), self) do
#           tag "colorsChanged"
          colorsChanged
        end
      end

    public

      def shadetype= aType
#         tag "setting shadetype to #{aType}"
        return if @shade_type == aType
        @shade_type = aType
        if @shade_type == :alpha
#           tag "Creating Pixmap 20, 20"
          pm = Qt::Pixmap.new(20, 20)
          Painter::new(pm) do |pmp|
            pmp.fillRect(0, 0, 10, 10, :lightGray)
            pmp.fillRect(10, 10, 10, 10, :lightGray)
            pmp.fillRect(0, 10, 10, 10, :darkGray)
            pmp.fillRect(10, 0, 10, 10, :darkGray)
          end
          pal = palette
#           tag "using pixmap as palette background brush for window!"
          pal.setBrush(backgroundRole, Qt::Brush.new(pm))
          self.autoFillBackground = true
          self.palette = pal
        else
          setAttribute Qt::WA_NoBackground
        end
      end

      def gradientStops= stops
        if @shade_type == :alpha
          @alpha_gradient = Qt::LinearGradient.new(0, 0, width, 0)
          stops.each do |pos, c|
            c = Qt::Color.new(c.red, c.green, c.blue) unless Qt::Color === c
            @alpha_gradient.setColorAt(pos, c)
          end
          @shade = nil
          shade!
          update
        end
      end

      @@borderPen = Qt::Pen.new(Qt::Color.new(146, 146, 146))

      def paintEvent e
#         tag "paintEvent"
#         tag "did generateShade, now create Painter"
        Painter.new(self) do |p|
          p.drawImage(0, 0, shade!)
          p.pen = @@borderPen
          p.drawRect(0, 0, width - 1, height - 1)
        end
#         tag "done paintEvesnt"
      end

      # this is important, as scaling down will cast all points to 0.0 ....
      def minimumSizeHint
        Qt::Size.new(50, 50)
      end

      def sizeHint
#         tag "THIS IS BAD MAN, but constructor assumes resizing is not possible, in other words, we must respond to resize. Hard?"
        InitSize # Qt::Size.new(150, 40)
      end

      def points
        @hoverPoints.points
      end

      attr :hoverPoints

      # returns 32bit argb value (Qt::Rgb). On failure 0 (opaque black) is returned
      def colorAt x
#         tag "colorAt #{x}"
        y = @hoverPoints[x] or return 0
        s = shade!
        s.pixel([x, s.width - 1.0].min.round, [y, s.height - 1.0].min.round)
      end

#       def colorsChanged
#       end

      signals "colorsChanged()"

      attr :gradientStops
      alias :stops :gradientStops
      alias :stops= :gradientStops=
    private

      MapColor = { red: Qt::Color.new(Qt::red), green: Qt::Color.new(Qt::green), blue: Qt::Color.new(Qt::blue) }

      def shade! # but only when init. or resized
        if !@shade || @shade.size != size
          if @shade_type == :alpha
#             tag "generateShade, argb"
            @shade = Qt::Image.new(size, Qt::Image::Format_ARGB32_Premultiplied)
            @shade.fill(0)
            Painter.new(@shade) do |p|
              p.fillRect(rect, @alpha_gradient)
              p.compositionMode = Qt::Painter::CompositionMode_DestinationIn
              fade = Qt::LinearGradient.new(0, 0, 0, height)
              fade.setColorAt(0, Qt::Color.new(0, 0, 0, 255))
              fade.setColorAt(1, Qt::Color.new(0, 0, 0, 0))
              p.fillRect(rect, fade)
            end
          else
#             tag "generateShade, #@shade_type"
            @shade = Qt::Image.new(size, Qt::Image::Format_RGB32)
            shade = Qt::LinearGradient.new(0, 0, 0, height)
            shade.setColorAt(1, Qt::Color.new(Qt::black))
            shade.setColorAt(0, MapColor[@shade_type])
            Painter.new(@shade) { |p| p.fillRect(rect, shade) }
          end
        end
        @shade
      end

  end # class QShadeWidget

  createInstantiator File.basename(__FILE__, '.rb'), QShadeWidget, ShadeWidget

end # module Reform