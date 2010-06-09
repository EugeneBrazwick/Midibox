
# tag "loading"

module Reform

  require_relative '../graphicsitem'

  class QReplicate < Qt::GraphicsItem #Group
    private
    def initialize parent, init_brush
      super(parent)
      @init_brush = init_brush
#       tag "init_brush.color=#{@init_brush.color.inspect}"
      # this is too simplistic, both scale and rotation require a pivot point to
      # be really usefull.
      @boundingrect = @count = @rotation = @scale = @translation = nil
      @fillhue_rotation = nil
      @myChildItems = []
    end

    private
    def matrix!
      unless @matrix
#         tag "calc mat, tran=#{@translation}, rot=#@rotation, scale=#@scale, count=#@count"
        @matrix = Qt::Transform.new
        @matrix.rotate(@rotation) if @rotation
        @matrix.scale(@scale) if @scale
        @matrix.translate(*@translation) if @translation
#         tag "calced {#{@matrix.m11} #{@matrix.m12} #{@matrix.m13}|#{@matrix.m21} #{@matrix.m22} #{@matrix.m23}|#{@matrix.m31} #{@matrix.m32} #{@matrix.m33}}"
      end
      @matrix
    end

    public
    def boundingRect
      b = Qt::RectF.new
      @myChildItems.each { |i| b |= i.boundingRect }
#       tag "org boundingRect = #{b.inspect}" # super -> 0,0,0,0  ???
      return b unless @count && @count > 0
      m = matrix!
      @count.times { b |= m.mapRect(b) }
#       tag "resulting brect -> #{b.inspect}"
      b
    end

    #override
    def opaqueArea
#       tag "opaqueArea called, this may be extremely slow, must cache..."
      o = Qt::PainterPath.new
      @myChildItems.each { |i| o |= i.opaqueArea }
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
#       painter.pen = Qt::Pen.new(Qt::black)
#       painter.drawRect(boundingRect)
      @myChildItems.each do |i|
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
            @myChildItems.each do |i|
#               painter.drawRect(i.boundingRect)
              i.brush = @hue if @hue #&& i.respond_to?(:'setBrush')
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

    # note that floats between -1.0 and 1.0 are seen as a fraction of a 360 degree rotation.
    # So rotate 180 == rotate 180.0 == rotate 0.5
    # The rotation is clockwise. passing 0 or 0.0 is illegal.
    def rotation= degrees
      degrees *= 360.0 unless Integer === degrees || degrees.abs > 1.00000001
#       tag "rotation := #{degrees}"
      @rotation = degrees
      unless @count
        @count = (360.000001 / @rotation.abs).floor - 1
        @count = 0 if @count < 0
      end
    end

    def fillhue_rotation= degrees
      degrees *= 360.0 unless Integer === degrees || degrees.abs > 1.00000001
      @fillhue_rotation = degrees.floor
    end

    attr_accessor :count, :scale
    attr :myChildItems

    def translation=(x = nil, y = nil)
#       tag "translation"
      @translation = if y then [x, y] else x end
    end

  end

  # virtual replicator repeats its contents while painting,
  # using transformations
  class Replicate < GraphicsItem
    # make it possible to add both widgets and graphicitems
    include ControlContext, GraphicContext
  private
    def initialize frame, qtc
#       tag "new GraphicsItem"
      super
#       @components = []
    end

    define_simple_setter :degrees, :count, :scale, :fillhue_rotation,
                         :rotation

    def translation(x, y = nil)
      if y
        @qtc.translation = [x, y]
      else
        @qtc.translation = x
      end
    end

    public

    def pen
      containing_frame.pen
    end

    def brush
      containing_frame.brush
    end

    # override. it returns the added control
    def addControl control, quickyhash = nil, &block
#       tag "addControl to qtc=#@qtc, to add = #{control.qtc}"
#       @qtc.addToGroup(control.qtc)
#       control.qtc.parentItem = @qtc
      @qtc.myChildItems << control.qtc
      control.instance_eval(&block) if block
      control.setupQuickyhash(quickyhash) if quickyhash
#       tag "calling postSetup on #{control}"
      control.postSetup
#       tag "did postSetup"
#       control
    end

    def self.new_qt_implementor(qt_implementor_class, parent, qparent)
#       tag "replicate: instantiate a #{qt_implementor_class}"
      q = QReplicate.new(qparent, parent.brush)
    end

    # override
    def instantiate_child(reform_class, qt_implementor_class, qparent)
      # add the child to the tree (and hence to the scene) but make it invisible
      # otherwise we might create a dangling pointer (at least in the C++ version,
      # may qtruby has something that protects us from memoryleaks??)
      # All replicators elements are virtual. They do not respond to events.
      # use 'realize' to make them real.
      child = reform_class.new_qt_implementor(qt_implementor_class, self, qparent)
      child.hide
      child
    end

  end # class Replicate

  createInstantiator File.basename(__FILE__, '.rb'), QReplicate, Replicate
#   tag "test for Scene#replicate"
#   raise ReformError, 'oh no' unless Scene.private_method_defined?(:replicate)
end # module Reform