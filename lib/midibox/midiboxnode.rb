
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
=end
  # class representing item on the canvas.
  class Node < Reform::PathItem

    Palette = { red: [251, 44, 44],
                orange: [235, 154, 58],
                yellow: [241, 252, 126],
                green: [26, 231, 34],
                blue: [132 , 247, 248],
                purple: [103, 108, 239],
                pink: [249, 109, 238],
                gray: [206],
                black: [:black],
                white: [:white]
              }.inject({}) { |hash, el| k, v = el; hash[k] = Reform::Graphical::make_brush(*v); hash }

      # let's make them Qt native
      class QTitleBar < Qt::GraphicsPathItem
        private
          def initialize qparent, node
            super(qparent)
            @node = node  # for title + specs
            path = Qt::PainterPath.new
            path.addRoundedRect(0.0, 0.0, 50.0, 16.0, 8.0, 8.0)
            setPath path
            setPen Reform::Graphical::make_pen(:nopen)
            setBrush Palette[:red]
          end
      end

    private
      def initialize parent, qtc
        super
        @title = ''
        @collapsed = false
        @showinactive = true
        @showcontrols = true
        # avoid the term 'connector'. It is confusing
        @titlebar = QTitleBar.new(@qtc, self)
        @qtc.setPen Reform::Graphical::make_pen(:nopen)
        @qtc.setBrush Palette[:blue]
        re_gen
      end

      def re_gen
        path = Qt::PainterPath.new
        path.addRoundedRect(0, 0, 50, 200, 8, 8)
        @qtc.path = path
      end

      # all classes that inherit this class are stored here:
      @@nodes = []

    public
      attr :title

      def collapsed?
        @collapsed
      end

      def showinactive?
        @showinactive
      end

      def showcontrols?
        @showcontrols
      end

      # override(!)
      def self.inherited sub
        tag "ADDING #{sub} to @@nodes"
        @@nodes << sub
      end

      # array of all classes that inherit this class
      def self.nodes
        @@nodes
      end

      def self.qclass
        Qt::GraphicsPathItem
      end
  end


end # module Midibox
