
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
      define_setter Float, :rotation

      def fillhue_rotation val
        raise "DEPRECATED: fillhue_rotation, use 'step'"
      end

      # experimental.
      def step(&block)
        @qtc.stepper = block
      end

      def translate_first
        @qtc.translate_first = true
      end

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
        QReplicate.new qparent
      end

  end # class Replicate

  # IMPORTANT: these are NOT Qt::Objects!! So no parenting system!
  # WRONG. But it is now setParentItem en ChildItems to do stuff...
  class QReplicate < Qt::GraphicsItem #Group
    include
    private
      def initialize parent
        super(parent)
  #       tag "init_brush.color=#{@init_brush.color.inspect}"
        # this is too simplistic, both scale and rotation require a pivot point to
        # be really usefull.
        @boundingrect = @count = @rotation = @scale = @translation = nil
#         # this is joke really:
#         @fillhue_rotation = nil
        # A proc called for each step, for each item, passing the item number
        @steppermatrix = nil # ???
        @stepper = nil # ???
        @i = Qt::Transform.new
        @translate_first = false
        @count = 1
      end

      def matrix!
        if @steppermatrix
          # we cannot cache it!
          @matrix = Qt::Transform.new
          @matrix.instance_exec(@_reform_hack, &@steppermatrix)
        else
          unless @matrix
    #         tag "calc mat, tran=#{@translation}, rot=#@rotation, scale=#@scale, count=#@count"
            @matrix = Qt::Transform.new
            @matrix.translate(*@translation) if @translate_first
            @matrix.scale(*@scale) if @scale
            @matrix.rotate(@rotation) if @rotation
            @matrix.translate(*@translation) if @translation && !@translate_first
    #         tag "calced {#{@matrix.m11} #{@matrix.m12} #{@matrix.m13}|#{@matrix.m21} #{@matrix.m22} #{@matrix.m23}|#{@matrix.m31} #{@matrix.m32} #{@matrix.m33}}"
          end
        end
        @matrix
      end

      def proper_update rect
        scene.update(mapRectToScene(rect)) # OK!
      end

    public # QReplicate methods

      attr_accessor :steppermatrix, :translate_first, :stepper

      def pen= p; end
      def brush= b; end
      def font= f; end

      def boundingRect
        b = Qt::RectF.new
        childItems.each { |i| b |= i.boundingRect }
  #       tag "org boundingRect = #{b.inspect}" # super -> 0,0,0,0  ???
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
          if @stepper #&& i.respond_to?(:setBrush)
            if i.instance_variable_defined?(:@_repl_org_brush)
#               has_brush = true
              i.brush = Qt::Brush.new(i.instance_variable_get(:@_repl_org_brush))
            elsif i.respond_to?(:brush)
              i.instance_variable_set(:@_repl_org_brush, Qt::Brush.new(i.brush))
            end
            if i.instance_variable_defined?(:@_repl_org_pen)
#               has_pen = true
              i.pen = Qt::Pen.new(i.instance_variable_get(:@_repl_org_pen))
            elsif i.respond_to?(:pen)
              i.instance_variable_set(:@_repl_org_pen, Qt::Pen.new(i.pen))
            end
          end
          i.paint(painter, option, widget)
        end
        painter.save
        begin
#           painter.worldMatrixEnabled = true # ? doesn't matter
          m = matrix!
          # we also have the changing hue ..... arghh
          for n in 1..@count do
            painter.setWorldTransform(m, true)# combine with current matrix
#             setTransform(m, true) #true==combine
            # completely ignored, I think because each g-item has a matrix associated
            # and that is applied 'as is' ruining my efforts.
            # and if I change the matrix for all components?
            # Or for myself???
#             super(painter, option, widget)
            childItems.each do |i|
              i.instance_exec(@_reform_hack, n, &@stepper) if @stepper
#                 tag "painting i again, transformed, painter pen = #{painter.pen.inspect}"
              i.paint(painter, option, widget)
            end
          end
        ensure
          setTransform(@i) # restore to I ???????
          painter.restore
        end
      end

      # The rotation is clockwise
      def rotation= degrees
        prepareGeometryChange
        br1 = boundingRect
        @rotation = degrees
        unless @count
          @count = (360.000001 / @rotation.abs).floor - 1
          @count = 0 if @count < 0
        end
        br1 |= boundingRect
        @matrix = nil
        proper_update(br1)
      end

      def fillhue_rotation= degrees
        degrees *= 360.0 unless Integer === degrees || degrees.abs > 1.00000001
        @fillhue_rotation = degrees.floor
        @matrix = nil
        update
      end

      attr :count, :scale

      def count= c
        prepareGeometryChange
        br1 = boundingRect
        @count = c
        br1 |= boundingRect
        proper_update(br1)
      end

      def scale= x, y
        prepareGeometryChange
        br1 = boundingRect
        @scale = x, y
        @matrix = nil
        br1 |= boundingRect
        proper_update(br1)
      end

      def translation= x, y
        prepareGeometryChange
        br1 = boundingRect
        @translation = x, y
        @matrix = nil
        br1 |= boundingRect
        proper_update(br1)
      end

  end

  createInstantiator File.basename(__FILE__, '.rb'), QReplicate, Replicate
#   tag "test for Scene#replicate"
#   raise ReformError, 'oh no' unless Scene.private_method_defined?(:replicate)
end # module Reform