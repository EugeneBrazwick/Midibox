module Reform

  require_relative 'frame'
  require 'reform/graphical'

  class GraphicsItem < Control; end             # forward

  # a Canvas is a frame that can contain graphic items like 'circle' etc.
  class Canvas < Frame
    include Graphical, GraphicContext, AnimationContext, StateContext
    private

      def initialize p, qp, autolayout = true
        super
        @rotation = @scale = @translation = nil
        @qtc.setRenderHint(Qt::Painter::Antialiasing, true)
  #       @pen = defaultPen
  #       @brush = defaultBrush
      end

      define_simple_setter :renderHint, :cacheMode, :dragMode, :transformationAnchor, :viewportUpdateMode

      def_delegators :@qtc, :resetTransform, :render, :setViewport, :viewport=, :setRenderHint, :renderHint=

      # since you can use them in QGraphicsView without scope I thought it might be usefull copying these
      # on the other hand, using syms might be a more elegant solution...
      AnchorUnderMouse = Qt::GraphicsView::AnchorUnderMouse
      AnchorViewCenter = Qt::GraphicsView::AnchorViewCenter
      NoAnchor = Qt::GraphicsView::NoAnchor
      ScrollHandDrag = Qt::GraphicsView::ScrollHandDrag
      RubberBandDrag = Qt::GraphicsView::RubberBandDrag
      NoDrag = Qt::GraphicsView::NoDrag
      FullViewportUpdate = Qt::GraphicsView::FullViewportUpdate
      MinimalViewportUpdate = Qt::GraphicsView::MinimalViewportUpdate
      SmartViewportUpdate = Qt::GraphicsView::SmartViewportUpdate
      BoundingRectViewportUpdate = Qt::GraphicsView::BoundingRectViewportUpdate
      NoViewportUpdate = Qt::GraphicsView::NoViewportUpdate

      def autoscale
        @qtc.autoscale = 1.0
      end

      def antialiasing b = nil
        return @qtc.renderHints & Qt::Painter::Antialiasing if b.nil?
        @qtc.setRenderHint(Qt::Painter::Antialiasing, b)
      end

      def title t = nil
        return @qtc.windowTitle unless t
        @qtc.windowTitle = t
      end

      # a view may override the scene background, this is however not very much advised. DEPRECATED??
      # IMPORTANT: the background only works if there is in fact a scene present!!! So we make it
      def background *brush
  #       if brush.respond_to?(:to_str)
  #         # load the image, where the path is given.
  #         brush = Qt::Brush.new(Qt::Pixmap.new(brush))
  #       end
        scene.backgroundBrush = make_brush(*brush)
      end

      alias :backgroundBrush :background

      def infused_scene!
        scene
#         tag "infused_scene! -> #@infused_scene"
        @infused_scene
      end

  #     def scene!
  #       instance_variable_defined?(:@infused_scene) ? @infused_scene : scene
  #     end

      def parent_qtc_to_use_for control
  #       tag "parent_qtc_to_use_for #{control}, control <= GraphicsItem = #{control <= GraphicsItem}"
        if control <= GraphicsItem then nil else super end
      end

      # just delegation?
  #     def addGraphicsItem control, quickyhash = nil, &block
  #       scene.addGraphicsItem(control, quickyhash, &block)
  #     end

        # NOTE: this methods must be public!!
      def_delegators :infused_scene!, :addGraphicsItem, :registeredBrush,
                    :registeredPen, :area, :addAnimation, :addState

      def calc_matrix
        # avoid creating a lot of objects... Is this lame?
        @@i ||= Qt::Transform.new
        @@i.reset
        @@i.rotate(@rotation) if @rotation
        @@i.scale(@scale, @scale) if @scale
        @@i.translate(*@translation) if @translation
        @@i
      end

      def alignment value = nil
        return @qtc.alignment if value.nil?
        Symbol === value and value = AlignmentMap[value] || Qt::AlignLeft
        @qtc.alignment = value
      end

      def scrollBarPolicy hor, ver = nil
        ver ||= hor
        @qtc.horizontalScrollBarPolicy = hor
        @qtc.verticalScrollBarPolicy = ver
      end

    public

      # override since we must set the scene here (setScene)
      def scene id = nil, &block
        return @qtc.scene unless id || block || !@qtc.scene
        case id
        when Hash, nil
          if instance_variable_defined?(:@infused_scene)
            @infused_scene.setup(id, &block)
          else
            newqtc = Qt::GraphicsScene.new containing_form.qtc
            require_relative 'scene'
            @infused_scene = Scene.new(self, newqtc)
  #           tag "#@infused_scene.addTo(#{self})"
            @infused_scene.addTo(self, nil, &block)
  #           tag "Added #@infused_scene to #{self}"
            @qtc.scene = newqtc
          end
        else
          raise 'scene already set' if instance_variable_defined?(:@infused_scene)
          @infused_scene = if id.respond_to?(:qtc) then id else containing_form[id] end
          newqtc = @infused_scene.qtc
          @qtc.scene = newqtc
        end
      end

      def_delegators :infused_scene!, :brush, :stroke, :fill #, :pen

      # FIXME this is a delegator too:
      def pen *args, &block
#         tag "calling #{infused_scene!}.pen()"
        infused_scene!.pen(*args, &block)
      end

      # rotate clockwise around center of the canvas.
      def rotate deg
        self.rotation = @rotation + deg
      end

      # change rotation only
      def rotation= deg
        @rotation = deg
        @qtc.transform = calc_matrix
      end

      def scale value = nil
        return @scale || 1.0 unless value
        @scale = value
        @qtc.transform = calc_matrix
      end

      def rotation deg = nil
        return @rotation || 0 if deg.nil?
        self.rotation = deg
      end

      def addScene control, hash, &block
        @qtc.scene = control.qtc
        # or 'super' .....
        control.setup hash, &block
        added control
      end

  end # class Canvas

  # The implementor:
  class QGraphicsView < Qt::GraphicsView
    include QWidgetHackContext          # This destroys the original painting procedure!!!
  # And I think I know why. It always creates a painter with begin + end.
  # It should never do this if the user has not defined a whenPainted callback!!
  # And also it shows that this method is fatally flawed
    private

    public

    attr :autoscale

      def autoscale= value
        policy = (@autoscale = value) ? Qt::ScrollBarAlwaysOff : Qt::ScrollBarAsNeeded
        setHorizontalScrollBarPolicy policy
        setVerticalScrollBarPolicy policy
      end

      # override Qt virtual method. Unfortunately there is no slot/signal for this.
      def resizeEvent event
        return super unless autoscale
        w, h = event.size.width, event.size.height
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
      def paint_target
        viewport
      end

  end # class QGraphicsView

#   tag "CALLING createInstantiator #{File.basename(__FILE__, '.rb')}"
  createInstantiator(File.basename(__FILE__, '.rb').to_sym, QGraphicsView,
                     Canvas)

end # Reform