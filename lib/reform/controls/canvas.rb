module Reform

  require_relative 'frame'

  class Canvas < Frame
    require_relative '../graphical'
    include Graphical
  private
    define_simple_setter :renderHint, :cacheMode, :dragMode

    def autoscale
      @qtc.autoscale = 1.0
    end

    def antialiasing b = nil
      return renderHints & Qt::Painter::Antialiasing if b.nil?
      setRenderHint(Qt::Painter::Antialiasing, b)
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

  public

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
       b = @_canvas_hack.whenResized and b[w, h]
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

  createInstantiator File.basename(__FILE__, '.rb'), QGraphicsView, Canvas

end # Reform