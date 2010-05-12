
# tag "loading"

module Reform

  require_relative '../graphicsitem'

  class QReplicate < Qt::GraphicsItemGroup
    private
    def initialize parent = nil
      super
      @boundingrect = @count = @rotation = @scale = @translation = nil
      @fillhue_rotation = nil
    end

    private
    def matrix!
      unless @matrix
        tag "calc mat, tran=#{@translation}, rot=#@rotation, scale=#@scale, count=#@count"
        @matrix = Qt::Transform.new
        @matrix.translate(*@translation) if @translation
        @matrix.rotate(@rotation) if @rotation
        @matrix.scale(@scale) if @scale
        tag "calced {#{@matrix.m11} #{@matrix.m12} #{@matrix.m13}|#{@matrix.m21} #{@matrix.m22} #{@matrix.m23}|#{@matrix.m31} #{@matrix.m32} #{@matrix.m33}}"
      end
      @matrix
    end

    public
    def boundingRect
      b = super
      return b unless @count && @count > 0
      m = matrix!
      @count.times { b |= m.mapRect(b) }
      b
    end

    #override
    def opaqueArea
      o = super
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
      super
      if @count && @count > 0
        painter.save
        begin
          painter.worldMatrixEnabled = true # ?
          m = matrix!
#           tran = Qt::Transform.new
#           tran *= m
          # we also have the changing hue ..... arghh
          @count.times do # |t| OK
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
              i.paint(painter, option, widget)
            end
#             tran *= m
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
      tag "rotation := #{degrees}"
      @rotation = degrees
      unless @count
        @count = (360.000001 / @rotation.abs).floor - 1
        @count = 0 if @count < 0
      end
    end

    attr_accessor :count, :scale, :fillhue_rotation

    def translation=(x = nil, y = nil)
      tag "translation"
      @translation = if y then [x, y] else x end
    end

  end

  # virtual replicator repeats its contents while painting,
  # using transformations
  class Replicate < GraphicsItem
    # make it possible to add both widgets and graphicitems
    include FrameContext, SceneContext
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

    # override. it returns the added control
    def addControl control, &block
#       tag "addControl to qtc=#@qtc, to add = #{control.qtc}"
#       @qtc.addToGroup(control.qtc)
      control.qtc.parentItem = @qtc
      control.instance_eval(&block) if block
#       tag "calling postSetup on #{control}"
      control.postSetup
#       tag "did postSetup"
#       control
    end

  end # class Replicate

  createInstantiator File.basename(__FILE__, '.rb'), QReplicate, Replicate
#   tag "test for Scene#replicate"
#   raise ReformError, 'oh no' unless Scene.private_method_defined?(:replicate)
end # module Reform