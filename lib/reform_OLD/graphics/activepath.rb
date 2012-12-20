
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative 'graphicspath'

# extends PathItem with the ability to move the vertices around, keeping the path constraints
# active.
# It would be easy now, to extend it with functionality of moving controlpoints as well,
# but I don't see the use of this, as I'm going to use 'autosmoothing' anyway.
  class ActivePathItem < PathItem

      # Note that Ellipse uses an offset to paint itself, and these controllers
      # normally all have position 0,0 (!)
      # This is inconvenient, so we make the topleft always 0.0
      class QController < Qt::GraphicsEllipseItem
        private
          # note the 'vertex' is in fact a Vertex as supplied by PathBuilder
          def initialize(parent, vertex, vertex_index, radius)
            super(-radius, -radius, radius * 2, radius * 2, parent.qtc)
            self.setPos(vertex.x, vertex.y)
            @vertex_index, @item = vertex_index, parent # the ActivePathItem itself
            setFlag(Qt::GraphicsItem::ItemSendsGeometryChanges, true)
          end
        public
          # override.
          # As a result of cleverly setting the pos, the resulting pos here is
          # the new value of the vertex we are controlling!
          def itemChange(itemchange, qvariant)
            if itemchange == Qt::GraphicsItem::ItemPositionHasChanged
              pos = qvariant.value
#               tag "notification PosChanged to #{pos.inspect}, self.pos=#{self.pos.inspect}"
              @item.setVertexPos(@vertex_index, pos.x, pos.y)
            end
            qvariant
          end
      end # class QController

    private # ActivePathItem methods
      # we inherit: @path (being build), @first_subpathnode
      # the trick is that we use a 'Builder' pattern.
      def initialize parent, qtc
        super
        @path = PathBuilder.new(self)
        @ctrlr_radius = 5.0
        @ctrlr_pen = Graphical::make_qtpen(:red)
        @ctrlr_brush = Graphical::make_qtbrush(:no_brush)
        @ctrlr_cursor = Qt::PointingHandCursor
      end

      def controller_radius x
        @ctrlr_radius = x
      end

      CursorMap = { arrow: Qt::ArrowCursor, up_arrow: Qt::UpArrowCursor, cross: Qt::CrossCursor,
                    wait: Qt::WaitCursor, ibeam: Qt::IBeamCursor, size_ver: Qt::SizeVerCursor,
                    size_hor: Qt::SizeHorCursor, size_bdiag: Qt::SizeBDiagCursor,
                    size_fdiag: Qt::SizeFDiagCursor, blank: Qt::BlankCursor, splitv: Qt::SplitVCursor,
                    splith: Qt::SplitHCursor,
                    pointing_hand: Qt::PointingHandCursor, forbidden: Qt::ForbiddenCursor,
                    open_hand: Qt::OpenHandCursor, closed_hand: Qt::ClosedHandCursor,
                    whats_this: Qt::WhatsThisCursor, busy: Qt::BusyCursor }

      def controller_cursor x
        @ctrlr_cursor = Symbol === x ? CursorMap[x] || Qt::ArrowCursor : x
      end

      def controller_pen(*args, &block)
        @ctrlr_pen = make_qtpen(*args, &block)
      end

      def controller_brush(*args, &block)
        @ctrlr_brush = make_qtbrush(*args, &block)
      end

      def assignQPath
        @qtc.path = @path.build
        for v, i in @path.each_vertex.each_with_index
#           tag "? v = #{v.class}-(#{v.x}, #{v.y})"
          el = QController.new(self, v, i, @ctrlr_radius)
          el.pen, el.brush = @ctrlr_pen, @ctrlr_brush
          el.cursor = Qt::Cursor.new(@ctrlr_cursor)
          el.setFlag Qt::GraphicsItem::ItemIsMovable, true
        end
      end

    public

      # callback, request to alter index.
      def setVertexPos vertex_index, x, y
        @path[vertex_index].pos = x, y
        @qtc.path = @path.path
      end

  end # class ActivePathItem

  createInstantiator File.basename(__FILE__, '.rb'), QGraphicsPathItem, ActivePathItem
#   tag "test for Scene#circle"
#   raise ReformError, 'oh no' unless Scene.private_method_defined?(:circle)

end # Reform