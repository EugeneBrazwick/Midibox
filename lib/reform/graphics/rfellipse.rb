
# Copyright (c) 2011 Eugene Brazwick

module Reform

  require 'reform/graphicsitem'

#   tag "HERE"

# the default pos is 0,0 and the width 100
  class ReformEllipse < GraphicsItem
    private

      # works well with center, but NOT with topleft or bottomright!
      def size w, h = nil
        return @qtc.size unless w
        w, h = w if Array === w
#         tag "width:=#{w}, qtc.rect := #{@qtc.x}, #{@qtc.y}, #{w}, #{w}"
        @qtc.size = Qt::SizeF.new(w, h || w)
      end

      # MESSY. This sets center based on the current radius.
      # it should be followed by bottomright! Not to be used with radius or size.
      # For 'topleft + size' use 'geometry' instead!!
      def topleft tx = nil, ty = nil
        return @qtc.topleft unless tx
        tx, ty = tx if Array === tx
#         tag "qtc.setPos := #{tx}, #{ty}, rect = #{@qtc.rect.inspect}"
        @qtc.topleft = Qt::PointF.new(tx, ty || tx)
      end

      # bottomright must be done AFTER topleft is set.
      def bottomright tx = nil, ty = nil
        return @qtc.bottomright unless tx
        tx, ty = tx if Array === tx
        @qtc.bottomright = Qt::PointF.new(tx, ty || tx)
      end

      # works well with radius and size, but NOT with topleft or bottomright!
      def center tx = nil, ty = nil
        return @qtc.center unless tx
        tx, ty = tx if Array === tx
#         tag "qtc.setPos := #{tx}, #{ty}, rect = #{@qtc.rect.inspect}"
        @qtc.center = Qt::PointF.new(tx, ty || tx)
      end

      # works well with center, but NOT with topleft or bottomright!
      def radius w = nil, h = nil
        return @qtc.radius unless w
        w, h = w if Array === w
        @qtc.radius = Qt::SizeF.new(w, h || w)
      end

      # in degrees, where 0 degrees is East, 90 is North etc. So counterclockwise.
      def startAngle degrees = nil
        return @qtc.startAngle unless degrees
        @qtc.startAngle = degrees
      end

      def spanAngle degrees = nil
        return @qtc.spanAngle unless degrees
        @qtc.spanAngle = degrees
      end

      def stopAngle degrees = nil
        return @qtc.startAngle + @qtc.spanAngle unless degrees
        @qtc.spanAngle = degrees - @qtc.startAngle
      end

      alias :from :startAngle
      alias :to :stopAngle
      alias :span :spanAngle

    public # ReformEllipse methods

      # override BAD default.... Note that this is topleft + size!
      def geometry=(*value)
        value = value[0] if value.length == 1
        v3 = value[3] || value[2]
#         tag "geometry = #{value.inspect}, v3 = #{v3}, value[2] = #{value[2]}"
        r = @qtc.radius
        r.width, r.height = value[2] / 2.0, v3 / 2.0
        @qtc.center = Qt::PointF.new(value[0] + r.width, value[1] + r.height)
      end

  end # ReformEllipse

#   tag "HERE"

  # The difference is we use center as 0,0
  class QReformEllipseItem < Qt::AbstractGraphicsShapeItem
    include QGraphicsItemHackContext
      FullCircleDegrees = 360.0
    private
      def initialize qparent
        super
        @center = Qt::PointF.new(0, 0)
        @radius = Qt::SizeF.new(50, 50)
        @startAngle = 0
        @spanAngle = FullCircleDegrees
        prepareGeometryChange
        @boundingRect = Qt::RectF.new
        update
      end

      def full?
        a = @spanAngle.abs
        return false unless a >= 0.0001
        a = a % 360.0
        a <= 0.0001 || a >= 359.9999
      end

      def drawEllipsePart painter, rect, from, to
        painter.drawPie rect, from, to
      end

    public
      # startAngle and spanAngle are integers. To get degrees divide by 16.0
      attr :center, :radius, :startAngle, :spanAngle

      def center= val
        return if @center == val
        prepareGeometryChange
        @center = val
        @boundingRect = Qt::RectF.new
        update
      end

      def radius= val
        return if @radius == val
        prepareGeometryChange
        @radius = val
        @boundingRect = Qt::RectF.new
        update
      end

      def topleft= val
        self.center = Qt::PointF.new(val.x + @radius.width, val.y + @radius.height)
#         tag "topleft:=#{val.inspect}, center := #{center.inspect}, rad=#{@radius.inspect}"
      end

      def topleft
        Qt::PointF.new(@center.x - @radius.width, @center.y - @radius.height)
      end

      # this is not symmetrical. It changes BOTH center and radius
      # This means topleft must be FIRST.
      def bottomright= val
        # 1 get 'top' back
        tx, ty = @center.x - @radius.width, @center.y - @radius.height
        # center is half of this
        @center.x, @center.y = (val.x + tx) / 2.0, (val.y + ty) / 2.0
        self.radius = Qt::SizeF.new(@center.x - tx, @center.y - ty)
#         tag "br:=#{val.inspect}, t=(#{tx},#{ty}), center := #{center.inspect}, rad=#{@radius.inspect}"
      end

      def bottomright
        Qt::PointF.new(@center.left + @radius.width, @center.top + @radius.height)
      end

      def size= val
        self.radius = Qt::SizeF.new(val.width / 2.0, val.height / 2.0)
      end

      def size
        Qt::SizeF.new(@radius.width * 2.0, @radius.height * 2.0)
      end

      # angle in degrees
      def spanAngle= angle
        return if angle == @spanAngle
        prepareGeometryChange
        @spanAngle = angle
        @boundingRect = Qt::RectF.new
        update
      end

      def startAngle= angle
        return if angle == @startAngle
        prepareGeometryChange
        @startAngle = angle
        @boundingRect = Qt::RectF.new
        update
      end

      def rect
#         tag "rect, center: (#{@center.x},#{@center.y}), radius: #{@radius.inspect}"
        Qt::RectF.new(@center.x - @radius.width, @center.y - @radius.height, 2 * @radius.width, 2 * @radius.height)
      end

      # override
      def boundingRect
        if @boundingRect.null?
          pw = pen.widthF
          if pw == 0.0 || full?
            @boundingRect = rect
          else
            @boundingRect = shape.controlPointRect
          end
        end
        @boundingRect
      end

      # override
      def shape
        path = Qt::PainterPath.new
        rct = rect
        return path if rct.isNull
        if full?
          path.addEllipse rct
        else
          path.moveTo(@center)
          path.arcTo(rct, (@startAngle * 16).round, (@spanAngle * 16).round)
        end
        ps = Qt::PainterPathStroker.new
        ps.capStyle = pen.capStyle
        ps.width = pen.widthF <= 0.0 ? 0.00000001 : pen.widthF
        ps.joinStyle = pen.joinStyle
        ps.miterLimit = pen.miterLimit
        p = ps.createStroke(path)
        p.addPath(path)
        p
      end

      #override
      def paint painter, option, widget
        painter.pen = pen # .tap{|t|tag "pen.color=#{pen.color.inspect}"}
        painter.brush = brush
        if full?
          painter.drawEllipse(rect)
        else
          drawEllipsePart(painter, rect, (@startAngle * 16).round, (@spanAngle * 16).round)
        end
        if selected?   # does not work -> (option.state & Qt::Style::State_Selected) != 0
          murect = painter.transform.mapRect(Qt::RectF.new(0, 0, 1, 1))
          if [murect.width, murect.height].max > 0.0001
            br = boundingRect
            mbrect = painter.transform.mapRect(br)
            if [mbrect.width, mbrect.height].min >= 1.0
              itemPenWidth = pen.widthF
              pad = itemPenWidth / 2.0
              penWidth = 0.0
              fgcolor = option.palette.windowText.color
              bgcolor = Qt::Color.new(fgcolor.red > 127 ? 0 : 255, fgcolor.green > 127 ? 0 : 255,
                                      fgcolor.blue > 127 ? 0 : 255)
              painter.pen = Qt::Pen.new(bgcolor, penWidth, Qt::SolidLine)
              painter.brush = Qt::Brush.new(Qt::NoBrush)
              bradj = br.adjusted(pad, pad, -pad, -pad)
              painter.drawRect(bradj)
              painter.pen = Qt::Pen.new(option.palette.windowText, 0, Qt::DashLine)
              painter.drawRect(bradj)
            end
          end
        end
      end

#       def setPen p
#         tag "pen := #{p.color.red}, #{p.color.green}, #{p.color.blue}"
#         super
#       end

#       def pen= p
#         setPen p
#       end
  end # class QReformEllipseItem

#   tag "calling createInstantiator"
  createInstantiator File.basename(__FILE__, '.rb'), QReformEllipseItem, ReformEllipse
#   tag "OK"

end # Reform