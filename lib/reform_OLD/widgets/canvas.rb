module Reform

  require_relative 'frame'
  require 'reform/graphical'

  class GraphicsItem < Control; end             # forward

=begin
   a Canvas is a frame that displays a scene.

   All items added to the canvas are actually added to the scene instead, but two canvasses
   can share a scene. To avoid having to create a scene a canvas without an explicit scene
   creates an implicit one internally.

   the Scene can contain graphic items like 'circle' etc.


=============================================================
TRANSFORMATIONS
=============================================================

We follow graphicsitem where you can set rotation + scale + translation.

Q: is rotate + translate the same as translate + rotate?
A: YES

Q: does Qt like transforming the canvas?
A: NO. In particular, the items may drop of the screen. Scrollbars are placed inaccurately etc.
But maybe I do something wrong?
For the time being, it is better to use a wrapping empty!!

++++++++++++++++++++
Canvas size
++++++++++++++++++++

If items fall from the screen the canvas does not become bigger.
=end
  class Canvas < Widget
    include Graphical, GraphicContext, AnimationContext, StateContext
    private

      def initialize p, qp #  , autolayout = true meaningless
        super
        @rotation = @scale = @translation = nil
        @qtc.setRenderHint(Qt::Painter::Antialiasing, true)
  #       @pen = defaultPen
  #       @brush = defaultBrush
      end

      define_simple_setter :renderHint, :cacheMode, :dragMode, :transformationAnchor

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

      VUPModeMap = { full: Qt::GraphicsView::FullViewportUpdate, default: Qt::GraphicsView::MinimalViewportUpdate,
                     minimal: Qt::GraphicsView::MinimalViewportUpdate, smart: Qt::GraphicsView::SmartViewportUpdate,
                     boundingrect: Qt::GraphicsView::BoundingRectViewportUpdate,
                     none: Qt::GraphicsView::NoViewportUpdate }

      def viewportUpdateMode value = nil
        return @qtc.viewportUpdateMode unless value
        value = VUPModeMap[value] || Qt::GraphicsView::MinimalViewportUpdate if Symbol === value
        @qtc.viewportUpdateMode = value
      end

      def mouse
        @qtc.mouse2data = true
        @qtc.mouseTracking = true
      end

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

      def infused_scene!
        qscene
#         tag "infused_scene! -> #@infused_scene"
        @infused_scene
      end

  #     def scene!
  #       instance_variable_defined?(:@infused_scene) ? @infused_scene : scene
  #     end

      def parent_qtc_to_use_for controlklass
  #       tag "parent_qtc_to_use_for #{control}, control <= GraphicsItem = #{control <= GraphicsItem}"
        if controlklass <= GraphicsItem then nil else super end
      end

        # NOTE: these methods must be public!!
      def_delegators :infused_scene!, :addGraphicsItem, :registeredBrush,
                    :registeredPen, :area, :addAnimation, :addState, :background

      alias :backgroundBrush :background

      def calc_matrix
        # avoid creating a lot of objects... Is this lame?
        @@i ||= Qt::Transform.new
        @@i.reset
        # rotate and scale can switch
        @@i.rotate(@rotation) if @rotation
        @@i.scale(*@scale) if @scale
        # but translation must be performed last!!
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

      def qscene id = nil, &block
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

    public

      # override since we must set the scene here (setScene)
      def_delegators :infused_scene!, :brush, :stroke, :fill, :pen, :font

      # rotate clockwise around center of the canvas. ILLEGAL....
      def rotate deg
        fprintf(stderr, "DEPRECATED method 'Canvas#rotate' called")
        self.rotation = @rotation + deg
      end

      # change rotation only
      def rotation= deg
        @rotation = deg
        @qtc.transform = calc_matrix
      end

      def scale x = nil, y = nil
        return @scale || [1.0, 1.0] unless x
        @scale = x, y || x
        @qtc.transform = calc_matrix
      end

      # IMPORTANT: scrollbars may appear and the items may fall from the view!
      def rotation deg = nil
        return @rotation || 0 unless deg
        self.rotation = deg
      end

      # IMPORTANT: Qt's view automatically uses the same area anyway
      # This may be wrong but it implies translating the view has not much use,
      # accept to create positions that match better with an existing system or so.
      def translation x = nil, y = nil
        return @translation || [0.0, 0.0] unless x
        @translation = x, y
        @qtc.transform = calc_matrix
        scene = infused_scene!
        area = scene.area
#         tag "area is now #{area.inspect}"
        tl = area.topLeft
        area.moveTopLeft Qt::PointF.new(tl.x - x, tl.y - y)
#         tag "translated area to #{area.inspect}, x=#{x}, y=#{y}"
        scene.area = area
      end

      def addScene control, hash, &block
        @qtc.scene = control.qtc
        # or 'super' .....
        control.setup hash, &block
        added control
      end

      # override
      def add child, quickyhash, &block
#         tag "#{self}::add #{child}"
        child.addTo(infused_scene!, quickyhash, &block)
      end

      def whenMouseMoved event = nil, &block
        if block # is a proc actually
          @whenMouseMoved = block
        else
          return instance_variable_defined?(:@whenMouseMoved) unless event # so no args passed at all.
          rfCallBlockBack(event, &@whenMouseMoved)
        end
      end

      def whenMouseMoved?
        instance_variable_defined?(:@whenMouseMoved)
      end

      class MouseWrapper < AbstractModel
        extend Forwardable
        private
          def initialize ev
            super()
            @event = ev
          end
        public
          # pseudo attrib
          def mouse
            self
          end

          def_delegators :@event, :scenePos, :button, :globalPos, :globalX, :globalY

          def pressed?
            @event.buttons != Qt::NoButton
          end

          def sceneX
            @event.scenePos.x
          end

          def sceneY
            @event.scenePos.y
          end

          def model?
            true
          end

          # returns hash, since flags type in qtruby is totally broken.
          def buttons
            r = {}
            b = @event.buttons
            r[:left] = true if (b & Qt::LeftButton.to_i) != 0
            r[:middle] = true if (b & Qt::MiddleButton.to_i) != 0
            r[:right] = true if (b & Qt::RightButton.to_i) != 0
            r
          end
      end

      def mouse2data event
        require 'reform/model'
#         tag "Calling updateModel with new MouseWrapper"
        prop = Propagation.new(self)
        prop.debug_track = true if track_propagation
        updateModel MouseWrapper.new(event), prop
      end
  end # class Canvas

  # The implementor:
  class QGraphicsView < Qt::GraphicsView
    include QWidgetHackContext          # This destroys the original painting procedure!!!
  # And I think I know why. It always creates a painter with begin + end.
  # It should never do this if the user has not defined a whenPainted callback!!
  # And also it shows that this method is fatally flawed
    private
      def initialize parent
        super
#         setTransformationAnchor NoAnchor              # I  can see no difference
        @mouse2data = false
      end

    public

      attr :autoscale
      attr_accessor :mouse2data

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

      def mouseMoveEvent event
        rfRescue do
          if instance_variable_defined?(:@_reform_hack)
            event.scenePos = mapToScene(event.pos)
            @_reform_hack.whenMouseMoved(event) if @_reform_hack.whenMouseMoved?
            if @mouse2data
#               tag "mouse2data!!"
              @_reform_hack.mouse2data(event)
            end
          end
          super
        end
      end

      def mousePressEvent event
        rfRescue do
          if instance_variable_defined?(:@_reform_hack)
            event.scenePos = mapToScene(event.pos)
            @_reform_hack.mouse2data(event) if @mouse2data
          end
          super
        end
      end

      def mouseReleaseEvent event
        rfRescue do
          if instance_variable_defined?(:@_reform_hack)
            event.scenePos = mapToScene(event.pos)
            @_reform_hack.mouse2data(event) if @mouse2data
          end
          super
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
