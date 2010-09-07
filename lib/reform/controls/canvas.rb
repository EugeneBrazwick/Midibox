module Reform

  require_relative 'frame'
  require_relative '../graphical'

  # a Canvas is a frame that can contain graphic items like 'circle' etc.
  class Canvas < Frame
    include Graphical
  private

    def initialize p, qp, autolayout = true
      super
      @rotation = @scale = @translation = nil
    end

    define_simple_setter :renderHint, :cacheMode, :dragMode

    def autoscale
      @qtc.autoscale = 1.0
    end

    def antialiasing b = nil
      return @qtc.renderHints & Qt::Painter::Antialiasing if b.nil?
      @qtc.setRenderHint(Qt::Painter::Antialiasing, b)
    end

    def initialize panel, qtc
      super
      @qtc.instance_variable_set :@_canvas_hack, self
      @qtc.setRenderHint(Qt::Painter::Antialiasing, true)
    end

    def title t = nil
      return @qtc.windowTitle unless t
      @qtc.windowTitle = t
    end

    # a view may override the scene background, this is however not very much adviced. DEPRECATED??
    def background brush
      if brush.respond_to?(:to_str)
        # load the image, where the path is given.
        brush = Qt::Brush.new(Qt::Pixmap.new(brush))
      end
      @qtc.backgroundBrush = brush
    end

    # override since we must set the scene here (setScene)
    def scene id = nil, &block
      if id
        newqtc = (if id.respond_to?(:qtc) then id else @owner.send(id) end).qtc
      else
        newqtc = Qt::GraphicsScene.new parent.qtc
        require_relative 'scene'
        c = Scene.new self, newqtc
        c.addTo(self, nil, &block)
      end
      @qtc.scene = newqtc
    end

    def calc_matrix
      # avoid creating a lot of objects... Is this lame?
      @@i ||= Qt::Transform.new
      @@i.reset
      @@i.rotate(@rotation) if @rotation
      @@i.scale(@scale) if @scale
      @@i.translate(*@translation) if @translation
      @@i
    end

  public

    # rotate clockwise around center of the canvas.
    def rotate deg
      self.rotation = @rotation + deg
    end

    # change rotation only
    def rotation= deg
      @rotation = deg
      @qtc.transform = calc_matrix
    end

    def rotation deg = nil
      return @rotation || 0 if deg.nil?
      self.rotation = deg
    end
  end # class Canvas

  # The implementor:
  class QGraphicsView < Qt::GraphicsView
    private

    public

     def autoscale= value
       policy = (@autoscale = value) ? Qt::ScrollBarAlwaysOff : Qt::ScrollBarAsNeeded
       setHorizontalScrollBarPolicy policy
       setVerticalScrollBarPolicy policy
     end

     # override Qt virtual method. Unfortunately there is no slot/signal for this.
     def resizeEvent event
       w, h = event.size.width, event.size.height
#        tag "calling #@_canvas_hack.whenResized(#{w}, #{h})"
#        @_canvas_hack.whenResized(w, h)
       if @autoscale && w > 4 && h > 4
#          fitInView(sceneRect, Qt::KeepAspectRatio)
         srect = sceneRect
         requested_scale = [w / srect.width, h / srect.height].min
#          tag "winsz=#{w}x#{h}, srect=#{srect.width}x#{srect.height} -> reqsc=#{requested_scale}"
         s, @autoscale = requested_scale / @autoscale, requested_scale
         scale(s, s) if (s - 1.0).abs > 0.001
       end
     end

     # override
     def sizeHint
       Qt::Size.new(*@_canvas_hack.requested_size)
     end
  end # class QGraphicsView

#   tag "CALLING createInstantiator #{File.basename(__FILE__, '.rb')}"
  createInstantiator File.basename(__FILE__, '.rb').to_sym, QGraphicsView, Canvas

end # Reform