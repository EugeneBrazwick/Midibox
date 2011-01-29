
# Copyright (c) 2010-2011 Eugene Brazwick

# tag "loading"

module Reform

  require 'reform/graphicsitem'

  # virtual replicator repeats its contents while painting,
  # using transformations
  class Replicate < GraphicsItem
    # make it possible to add both widgets and graphicitems
    include ControlContext # ????, GraphicContext (already in GraphicsItem obviously)
    private
      def initialize frame, qtc
  #       tag "new GraphicsItem"
        super
  #       @components = []
      end

      define_setter Integer, :count
      define_setter Qt::PointF, :scale, :translation
      define_setter Float, :fillhue_rotation, :rotation

    public # Replicate methods

      def pen
        parent.pen
      end

      def brush
        parent.brush
      end

      # Hack for stupid 'fillhue_rotation' hack. FIXME.
      def self.new_qt_implementor(qt_implementor_class, parent, qparent)
  #       tag "replicate: instantiate a #{qt_implementor_class}"
        QReplicate.new(qparent, parent.brush)
      end

  end # class Replicate

  # IMPORTANT: these are NOT Qt::Objects!! So no parenting system!
  # WRONG. But it is now setParentItem en ChildItems to do stuff...
  class QReplicate < Qt::GraphicsItem #Group
    private
      def initialize parent, init_brush
        super(parent)
        @init_brush = init_brush
  #       tag "init_brush.color=#{@init_brush.color.inspect}"
        # this is too simplistic, both scale and rotation require a pivot point to
        # be really usefull.
        @boundingrect = @count = @rotation = @scale = @translation = nil
        # this is joke really:
        @fillhue_rotation = nil
      end

      def matrix!
        unless @matrix
  #         tag "calc mat, tran=#{@translation}, rot=#@rotation, scale=#@scale, count=#@count"
          @matrix = Qt::Transform.new
          @matrix.rotate(@rotation) if @rotation
          @matrix.scale(*@scale) if @scale
          @matrix.translate(*@translation) if @translation
  #         tag "calced {#{@matrix.m11} #{@matrix.m12} #{@matrix.m13}|#{@matrix.m21} #{@matrix.m22} #{@matrix.m23}|#{@matrix.m31} #{@matrix.m32} #{@matrix.m33}}"
        end
        @matrix
      end

    public # QReplicate methods

      def pen= p; end
      def brush= b; end
      def font= f; end

      def boundingRect
        b = Qt::RectF.new
        childItems.each { |i| b |= i.boundingRect }
  #       tag "org boundingRect = #{b.inspect}" # super -> 0,0,0,0  ???
        return b unless @count && @count > 0
        m = matrix!
        @count.times { b |= m.mapRect(b) }
#         tag "resulting brect -> #{b.inspect}"
        b
      end

      #override
      def opaqueArea
  #       tag "opaqueArea called, this may be extremely slow, must cache..."
        o = Qt::PainterPath.new
        childItems.each { |i| o |= i.opaqueArea }
        return o unless @count && @count > 0
        m = matrix!
        @count.times { o |= m.map(o) }
        o
      end

      # 'override' hack. We are not a widget anyway.
      def inherits something
      end

      def paint painter, option, widget = nil
        # widget is the actual widget, but can be nil.
        # the method should paint to painter.
#          painter.pen = Qt::Pen.new(Qt::black)
#          painter.drawRect(boundingRect)       OK
        childItems.each do |i|
          # important 'respond_to?' will NOT work!!
  #         tag "#{i}.respond_to?(:setBrush) -> #{i.respond_to?(:setBrush)}"
          i.brush = @init_brush if @fillhue_rotation #&& i.respond_to?(:setBrush)
          i.paint(painter, option, widget)
        end
        @hue = @fillhue_rotation ? Qt::Brush.new(@init_brush) : nil
  #       tag "hue = #{@hue && @hue.color.inspect}"
        if @count && @count > 0
          painter.save
          begin
  #           painter.worldMatrixEnabled = true # ? doesn't matter
            m = matrix!
  #           tran = Qt::Transform.new
  #           tran *= m
            # we also have the changing hue ..... arghh
            @count.times do # |t| OK
              if @fillhue_rotation
                color = @hue.color
                hsv = color.hue, color.saturation, color.value, color.alpha
  #               tag "orgcolor = #{color.inspect}, orghsv = #{hsv.inspect}"
                hsv[0] = (hsv[0] + @fillhue_rotation) % 360
                color.setHsv(*hsv)
  #               tag "changing hsv to #{hsv.inspect}"
                @hue.color = color
              end
  #             tag "alter transform and repaint , t= #{t}" OK
  #             painter.translate(5.0, 5.0)
              painter.setWorldTransform(m, true) # combine with current matrix
  #             setTransform(m, true) #true==combine
              # completely ignored, I think because each g-item has a matrix associated
              # and that is applied 'as is' ruining my efforts.
              # and if I change the matrix for all components?
              # Or for myself???
  #             super(painter, option, widget)
              childItems.each do |i|
  #               painter.drawRect(i.boundingRect)
                i.brush = @hue if @hue #&& i.respond_to?(:'setBrush')
#                 tag "painting i again, transformed, painter pen = #{painter.pen.inspect}"
                i.paint(painter, option, widget)
                # sleep 1  HANG!!
              end
            end
          ensure
            setTransform(Qt::Transform.new) # restore to I
            painter.restore
          end
        end
      end

      # The rotation is clockwise
      def rotation= degrees
        @rotation = degrees
        unless @count
          @count = (360.000001 / @rotation.abs).floor - 1
          @count = 0 if @count < 0
        end
        @matrix = nil
        update
      end

      def fillhue_rotation= degrees
        degrees *= 360.0 unless Integer === degrees || degrees.abs > 1.00000001
        @fillhue_rotation = degrees.floor
        @matrix = nil
        update
      end

      attr :count, :scale

      def count= c
        br1 = boundingRect
        @count = c
        br1 |= boundingRect
        scene.update(mapRectToScene(br1)) # OK!
#         tag "count := #{c}, update display area: #{br1.inspect}"              SEEMS OK....
      end

      def scale= x, y
        @scale = x, y
        @matrix = nil
        update
      end

      def translation= x, y
        @translation = x, y
        @matrix = nil
        update
      end

  end

  createInstantiator File.basename(__FILE__, '.rb'), QReplicate, Replicate
#   tag "test for Scene#replicate"
#   raise ReformError, 'oh no' unless Scene.private_method_defined?(:replicate)
end # module Reform