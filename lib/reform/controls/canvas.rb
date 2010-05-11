module Reform

  require_relative 'frame'

  class Canvas < Frame
    require_relative '../graphical'
    include Graphical
  private
    define_simple_setter :renderHint, :cacheMode, :dragMode

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

    def scene id = nil, &block
      if id
        newqtc = (if id.respond_to?(:qtc) then id else @owner.send(id) end).qtc
      else
        newqtc = Qt::GraphicsScene.new @containing_frame.qtc
        require_relative 'scene'
        c = Scene.new self, newqtc
        addControl(c, &block)
      end
      @qtc.scene = newqtc
    end

  public

  end # class Canvas


  class QGraphicsView < Qt::GraphicsView
    public
     # override Qt virtual method. Unfortunately there is no slot/signal for this.
     def resizeEvent event
       b = @_canvas_hack.when_resized and
         b.call(event.size.width, event.size.height)
     end

     def sizeHint
       Qt::Size.new(*@_canvas_hack.requested_size)
     end
  end

  createInstantiator :canvas, QGraphicsView, Canvas

end # Reform