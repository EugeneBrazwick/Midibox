
require 'reform/graphics/graphicspath'

module Midibox

=begin

Blendernodes have 3 buttons on the titlebar.

LAYOUT
- triangle (left) shows name + active connections, nodes are '1 unit' high.
                  If pressed the node collapses until only the titlebar is visible
                  The titlebar can be stretched somewhat ('=' handle on the right)
                  When opened there is a sizer in the bottomright corner.
                  The '+' and '=' buttons are not visible, nor have they any impact
- title / name
- '+' button. If pressed than inactive connections show up, (plus their name)
- '=' button. Show the controls. These may be available per connection (active or not)
              or generic ones (on top).
              When 'input' mode is active the scaler can scale vertical as well
              (in fact it uses a fixed aspectratio shrink/expand).
              If this mode is not active, then the scaler can only stretch the
              control horizontally.
              Controls can also be readonly to show specific info in graphic format
              or otherwise.

Connections, on the left and right side. Left is input, right is output.

Connections
------------
- can have a control (input) widget. But only if inactive.
- have a type which needs not fit the connector. Colors, vectors, single values can be mixed anyway.
- get a highlight when hovering over them
- wires can be made by click and drag to a receiving node.
- wires can be cut by making a selection right through them

IMPLICIT connections ??
-------------------
Example:  'mix' it shows color (input). But you can connect
a second wire to the leftside and color2 appears, and then 'fac'
I say this but new mix nodes really show 4 connections, so it may be a bug even.

Windows
- are round on all corners except bottom right
- here is shading around them. But no line between controls or even the title bar
- the title bar has a different color
- controls are normally 1 unit high but often show the real controls when clicking on them.
  for example: color selection or vector inputs.


----------------------------------------------------
All components are graphicitems and child of ourselves. The mainclass
provides the outline and we add a Qt special effect to ourselves to
get the dropshadow.

The titlebar is a control of its own

---------------------------------------------------
Connection types
---------------------------------------------------
bool value - green1,  checkbox
int value -  green2,  edit, radio, slider, rotating knob
Real value - green3,  edit, slider, knob, etc..


voice - either a logical combination or a single voice (let's call that a part). A single voice is
        a logical instrument that
        maps to a device-instrument (in the end just a midi bytestring to activate it).
      - red

section - a 'vertical' section of the song itself. Bars. black

track - a sequence of midi events for a single voice. Can still be several channels. orange for in, blue for out.
channel - single channel midi data. Channels are between 1 and 16 (for real channels) 0 for messages without
a logical channel and 17-256 for any other alsa-channel. orange and blue.
Midibox ignores channels btw. They have no logical external meaning.
chunk - several or all tracks. orange and blue.

Note that blender uses left to right connections where the colors should match, but not really.

mappings/gradients. Represented by a small graph with managable handles. purple.

filters and other connectors. related to tracks. So orange and blue.

generators. orange only.

rhythm. Just an event at some time. Events have no value, but may have duration.

arpeggio. A short sequence (sequence) of events without rhythm.

chord(sequence). Arpeggio's can be given a a rhythm and a chord.

style. Stack of chordless (but chord driven) rhythms, instrumentation and patterns, that can
be lead by a chordsequence. Styles have variations and specific transitionphrases, introduction
and closephrases.

queuecontrol - to connect a position of play or even recording. pink.

Shortterm todolist;
  1) undo + redo   OK
  2) layout of nodes more concrete
    2a) loading svg's is a special case. Just passing it to 'load' will work but incorrect.
        gimp opens it correctly.  Solution: use png. Solution: use QSvgRenderer
        But it hard to see why Qt would not do this internally?
  3) can't delete them...
  4) connecting stuff
  5) changing the model and auto-saving.
  6) loading

=end
  # class representing item on the canvas.
  class Node < Reform::PathItem

      class QCollapseItem < Qt::GraphicsPixmapItem
        private
          def initialize qparent
            sz = $theme.glyphSize
#             tag "Scale images to size #{sz.inspect}"
            img = Qt::Pixmap.new($theme.collapseGlyphPath).scaled(sz, Qt::KeepAspectRatioByExpanding,
                                                                  Qt::SmoothTransformation)
            super img, qparent
            setPos(2, ($theme.titleH - img.height) / 2)
          end

        public  # QCollapseItem methods

          def mousePressEvent event
            super
            rfRescue do
#             tag "mousePressEvent"
              node = parentItem.node
              cmd = Midibox::AlterNodeStateCommand.new(node, collapsed: !node.collapsed?)
              $undo.push cmd
            end
          end

# #           def mouseReleaseEvent event
#             super
#             tag "mouseReleaseEvent"
#           end
      end # class QCollapseItem

      class QSizerItem < Qt::GraphicsPixmapItem
        private
          def initialize qparent
            sz = $theme.glyphSize
            @glyph = Qt::Pixmap.new($theme.sizerGlyphPath).scaled(sz * 0.67, Qt::KeepAspectRatioByExpanding,
                                                                  Qt::SmoothTransformation)
            super @glyph, @qtc
          end
        public  # QSizerItem methods
          attr :glyph

          def mousePressEvent event
            rfRescue do
              @mx, @my = event.pos.x, event.pos.y
#               orgsize = parentItem.node.qtc.boundingRect.size         # floats         RATIO????
              node = parentItem.node
              @orgw, @orgh = node.width.to_f, node.height.to_f
              @orgaspect = @orgw / @orgh  # cannot be 0
#               tag "m = (#@mx, #@my), orgsz=(#@orgw, #@orgh), ascpect=#@orgaspect"
              event.accept
            end
          end

          def mouseMoveEvent event
            rfRescue do
#               tag "MM, event.pos=(#{event.pos.x}, #{event.pos.y}), press_pos=(#@mx, #@my)"
              rx, ry = event.pos.x - @mx, event.pos.y - @my
              w, h = @orgw + rx, @orgh + ry
#               tag "r=(#{rx}, #{ry}), sz=(#{w}, #{h})"
              node = parentItem.node
              min, max = node.minSize, node.maxSize
              w = min.width if w < min.width
              w = max.widt5h if w > max.width
              h = min.height if h < min.height
              h = max.height if h > max.height
#               tag "after applying min(#{min.inspect}) and max(#{max.inspect}) -> sz=(#{w},#{h})"
=begin
  suppose we have a requested size of 200, 100
  but the aspectratio = 1.5
  This means the size should become 150, 100
  In fact Qt::Size has a method for it ....

  w = aspect * h
  -> h = w / aspect

  Apply the ratio to both original values, we get  w2, h2 = 1.5,
=end
              w2 = @orgaspect * h
              h2 = w / @orgaspect
              h = h2 if h2 < h
              w = w2 if w2 < w
              # It's a better idea using a prelim resize. Pressing Esc or Rbutton cancels the resize.
              # If you release the button the undo command is inserted.
              # However, UNDO is unstable so this is a good way of stresstesting it.
#               tag "after applying aspectratio #@orgaspect: -> sz=(#{w},#{h}), stacksize = #{$undo.activeStack.count}"
              node.resize(w, h)
            end
          end

          def mouseReleaseEvent event
#             tag "and release, orgw=#{@orgw.inspect}, orgh=#{@orgh.inspect}"
            node = parentItem.node
            if node.w != @orgw || node.h != @orgh
#               tag "node.w=#{node.w}, h=#{node.h}, org = #@orgw, #@orgh"
              $undo.push(ResizeNodeCommand.new(node, node.w, node.h, @orgw, @orgh))
            end
          end

      end # class QSizerItem

      # let's make them Qt native
      class QTitleBar < Qt::GraphicsPathItem
        private
          def initialize qparent, node
            super(qparent)
            @node = node  # for title + specs
            setPen Reform::Graphical::make_pen(:nopen)
            setBrush $theme.red
#             tag "creating textitem for title '#{@node.title}'"
            @textitem = Qt::GraphicsSimpleTextItem.new(@node.title, self)
            # it is 0 so worthless... So we must gamble here
            #tag "textitem.boundingRect = #{@textitem.boundingRect.inspect}, h = #{h}"

#             tag "Scale images to size #{sz.inspect}"
            @collapseitem = QCollapseItem.new(self)

            sz = $theme.glyphSize
            img = Qt::Pixmap.new($theme.expandGlyphPath).scaled(sz, Qt::KeepAspectRatioByExpanding,
                                                                Qt::SmoothTransformation)
            @expanditem = Qt::GraphicsPixmapItem.new(img, self)
            h = ($theme.titleH - img.height) / 2
            @expanditem.setPos(@node.width - 2 * (img.width + 4), h)

            img = Qt::Pixmap.new($theme.showcontrolsGlyphPath).scaled(sz, Qt::KeepAspectRatioByExpanding,
                                                                      Qt::SmoothTransformation)
            @showcontrolseitem = Qt::GraphicsPixmapItem.new(img, self)
            h = ($theme.titleH - img.height) / 2
            @showcontrolseitem.setPos(@node.width - (img.width + 4), h)
          end

        public # QTitleBar methods

          def title= value
            @textitem.text = value
            #tag "textitem.boundingRect = #{@textitem.boundingRect.inspect}, h = #{$theme.titleH}"
            @textitem.setPos(30, ($theme.titleH - @textitem.boundingRect.height) / 2)
          end

          def re_gen
            path = Qt::PainterPath.new
            w, h = @node.width, $theme.titleH
            r2 = $theme.radiusEdge
            path.arcMoveTo 0, 0, r2, r2, 180 # topleft, just below the arc
            path.arcTo 0, 0, r2, r2, 180, -90 # topleft arc
            path.arcTo w - r2, 0, r2, r2, 90, -90 # topright
            if @node.collapsed?
              # the bottom is rounded
              path.arcTo w - r2, h - r2, r2, r2, 0, -90 # bottomright
              path.arcTo 0, h - r2, r2, r2, 270, -90 # bottomleft
              @expanditem.hide
              @showcontrolseitem.hide
            else
              path.lineTo w, h
              path.lineTo 0, h
              @expanditem.show
              @showcontrolseitem.show
            end
            path.closeSubpath
            setPath path
          end

          attr :node
      end

    private # Node methods

      def initialize parent, qtc
        super
#         @qtc.instance_variable_set :@_reform_hack, self
        raise '???' unless @qtc.instance_variable_get(:@_reform_hack) == self
        @prevpos = nil
        @title = ''
        @collapsed = false
        @showinactive = true
        @showcontrols = true
        # avoid the term 'connector'. It is confusing
        @width = $theme.initW
        @height = $theme.titleH + 3 * $theme.unitH  # just testing
        @titlebar = QTitleBar.new(@qtc, self)
        @sizer = QSizerItem.new(@qtc)
        @qtc.setPen Reform::Graphical::make_pen $theme.red
        @qtc.setBrush $theme.orange
        re_gen
        dropshadow = Qt::GraphicsDropShadowEffect.new
        dropshadow.blurRadius = $theme.blurRadius
        dropshadow.color = $theme.blurColor
        @qtc.setGraphicsEffect dropshadow
        @qtc.setFlags(Qt::GraphicsItem::ItemIsSelectable | Qt::GraphicsItem::ItemIsMovable)
      end

      # It is not legal to change sizes here!!
      def re_gen
#         tag "re_gen, w=#@width, h=#@height"
        @titlebar.re_gen
        path = Qt::PainterPath.new
        unless @collapsed
          r2 = $theme.radiusEdge
          #this does not work. The main item must incorporate the title in its path.
          path.arcMoveTo 0, 0, r2, r2, 180 # topleft, just below the arc
          path.arcTo 0, 0, r2, r2, 180, -90 # topleft arc
          path.arcTo @width - r2, 0, r2, r2, 90, -90 # topright
          path.lineTo @width, @height           # lower right
          path.arcTo 0, @height - r2, r2, r2, 270, -90 # bottomleft
          path.closeSubpath
          @sizer.parentItem = @qtc
          @sizer.setPos(@width - @sizer.glyph.width - 2, @height - @sizer.glyph.height - 2)
        else
          # collapsed mode. @height is ignored!
          w, h = @width, $theme.titleH
          r2 = $theme.radiusEdge
          path.arcMoveTo 0, 0, r2, r2, 180 # topleft, just below the arc
          path.arcTo 0, 0, r2, r2, 180, -90 # topleft arc
          path.arcTo w - r2, 0, r2, r2, 90, -90 # topright
          path.arcTo w - r2, h - r2, r2, r2, 0, -90 # bottomright
          path.arcTo 0, h - r2, r2, r2, 270, -90 # bottomleft
          @sizer.parentItem = @titlebar
          @sizer.setPos(@width - @sizer.glyph.width - 2, (h - @sizer.glyph.height) / 2)
        end
        @qtc.path = path
      end

      # all classes that inherit this class are stored here:
      @@nodes = []

      def title= value
        @titlebar.title = value
      end

    public
      attr :title

      def self.iconpath
      end

      def state
        { collapsed: @collapsed, showinactive: @showinactive, showcontrols: @showcontrols }
      end

      def state= hash
        @collapsed, @showinactive, @showcontrols = hash[:collapsed], hash[:showinactive], hash[:showcontrols]
        re_gen
      end

      def minSize
        # we must use the minsize of each control....
        Qt::SizeF.new($theme.minWidth, $theme.titleH + (@collapsed ? 0.0 : 2.5 * $theme.unitH))
      end

      def maxSize
        Qt::SizeF.new(480.0, $theme.titleH + (@collapsed ? 0.0 : 4.5 * $theme.unitH))
      end

      def toggle_collapse
        @collapsed = !@collapsed
        re_gen
      end

      def collapsed?
        @collapsed
      end

      def resize w, h
        raise 'what?' unless w && h
        return if @width == w && @height == h
        @width, @height = w, h
        re_gen
      end

      def showinactive?
        @showinactive
      end

      def showcontrols?
        @showcontrols
      end

      # override(!)
      def self.inherited sub
#         tag "ADDING #{sub} to @@nodes"
        @@nodes << sub #unless sub.abstract?            At this point the class is still not completely defined!!
      end

      # array of all classes that inherit this class.
      #skipping those that are not abstract
      def self.nodes
        @@nodes.find_all do |n|
          #tag "n=#{n}, n.abstract? -> #{n.abstract?}";
          !n.abstract?
        end
      end

      def self.qclass
        QNodeItem
      end

      def self.abstract?
      end

      attr :width, :height

      alias :w :width
      alias :h :height

=begin
  Another Qt complication.  Moves are not recorded in the undolist, and how could they?
  But if I catch the ItemPositionHasChanged event and add the UndoCommand the
  command is redone... Even worse, executing the undo or the redo will cause this
  event to fire once more...

  ANOTHER QT CRAP BUMMER ANOIANCE:

    itemChange with PosChange is only called if setPos or moveBy is used. Not if the user moves
    the item...
    AARGHHH

  But what if it actually worked and the user drags the item. We get loads of events
  iso the release position!!
=end
#       def itemChange change, value
#         case change
#         when Qt::GraphicsItem::ItemPositionChange
#           # Not HasChanged, we need @qtc.pos being the original position.
#           $undo.push(MoveNodeCommand.new(self, value, @prevpos))
#           @prevpos = value
#         end
#         super
#       end

  end # class Node

  class QNodeItem < Qt::GraphicsPathItem
    include Reform::QGraphicsItemHackContext
    private
      def initialize parent = nil
        super
#         tag "QNodeItem, ItemSendsScenePosChanges + GeoChanges ON"
        setFlag(Qt::GraphicsItem::ItemSendsScenePositionChanges, true)
        setFlag(Qt::GraphicsItem::ItemSendsGeometryChanges, true)
      end

    public
      def mouseDoubleClickEvent event
        rfRescue { @_reform_hack.toggle_collapse }
        super
      end

      def mousePressEvent event
        @mpev_pos = pos
#         tag "mousePressEvent"
        super
      end

      def mouseReleaseEvent event
#         tag "mouseReleaseEvent"
        if @mpev_pos != pos
          $undo.push(MoveNodeCommand.new(@_reform_hack, pos, @mpev_pos))
        end
        super
      end

      def node
        @_reform_hack
      end

  end # class  QNodeItem

end # module Midibox