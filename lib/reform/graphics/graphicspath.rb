
=begin
The node-smoothing algorhytm stems from src/ui/tool/node.cpp from the inkscape source,
with the folling copyright notice:
/* Authors:
 *   Krzysztof Kosiński <tweenk.pl@gmail.com>
 *
 * Copyright (C) 2009 Authors
 * Released under GNU GPL, read the file 'COPYING' for more information
 */
=end

module Reform

  require 'reform/graphicsitem'

=begin

Now, Eugene has a phylosofical argument with methods like 'lineTo'.
As these implement a change, and not a declaration.

Especially 'moveTo'.

A path can be seen as a series of segments where the pen stays on the canvas
while adding stuff.
Let's represent that with the [] array notation.

This implies that adding two arrays like [...], [...] will cause a moveTo to be
implied.
In that terminology a line is just a vertex. And a vertex can be represented as a tuple
[x, y].

[[0,0],[1,0],[1,1]],[0,0],[-1,0],[0,-1]]

If we know we are dealing with a path and not a vertex then we can also write
[0,0, 1,0, 1,1],[0,0, -1,0, 0,-1]

Then we must decide how a path is 'closed'.
I would say that 'closing' is the default case, and leaving it open is special.
To do this the single element :open is to be used.

In the end only 3 elements exist in a path;  move, line and curve.

So [[0,0],[1,1]] is moveTo(0,0), lineTo(1,1)
Next we can say line(0,0, 1,1) or line([0,0],[1,1]). And to add segments just do:
  line(0,0, 1,1, 2,0, 1,0)
However, it should not close automatically.
  curve
should work  the same, And it is possible to use both as components of paths:

[ line(0,0, 1,1), line(2,0, 1,0)]
Since an array represents a 'pen down' part, the [2,0] starting the second line is lineTo
and not a moveTo. In this sense [line(0,0, 1,1), line(2,0)] is identical to
[0,0, 1,1, 2,0].

To close a line or curve anyway you can use :close as last element. So
line(0,0, 1,1, 1,0, :close) is equal to [0,0, 1,1, 1,0] or [0,0, 1,1, 1,0, 0,0, :open]
The last one is :open logically, but closed if we look to the coordinates. I say it should
be avoided, for this ambiguity. But to create a closed curve we must use it.

So we compose the path of components:

  - vertex, cannot occur on its own. Always part of a polyline
  - line. If in front then the first one is a move, all others are lineTo, including :close.
  - curve. Same as line but now curves. However :close is a lineTo.
  - :close. lineTo first point of path, plus a moveTo(0,0) Any trailing components are ignored
  - ellipse. all basic shapes add closed subpaths and implicitely close the previous path.
             They cannot be put inside paths. [0,0, 1,1], ellipse(....), [....]
             Also repetition of arguments is not handled.
  - rect
  - roundedrect
  - path
  - region. A region is not unlike a path, except that only the fill is taken into account.
            Normally used to define a clippingzone. Instead of adding polygons, you
            add basic rectangles, ellipses or bitmaps using '|', '&', '-' and '^'
  - text. Text is put on the coord where x = left (or right), and y the baseline.
  - polygon. left open
  - arc. The first coordinate here becomes a moveTo or lineTo, which is the center of
         the passed rectangle. Followed by startangle (0 == +x) and sweep-angle ccw.
         at that point on the arc it is left open.  So arc can be embedded in [].
         arc(rect, ang1, angd). Angles are in degrees.
  - cubic. Similar to arc. cubic(p1, c1, c2, p2, c3, c4, p3, ....)
           [line(p1, p2), line(p3, p4)] the p3 is a lineTo(p3)
           [cubic(p1, c1,c2, p2), cubic(p3, c1, c2, p4)]. p3 is also a lineTo(p3)
           cubic(p1, c1,c2, p2), cubic(p3, c1, c2, p4). p3 is a moveTo(p3)
           line(p1, p2), cubic(p2, c1, c2, p3). We must duplicate the vertex. But:
           [p1, cubic(p2, c1,c2, p3)] is the same.
  - quad. Second degree version of cubic (faster but less fluid).
           quad(p1, c2, p2, c2, p3, ...)
  - subpath. Same as []

Lacking: arcMoveTo (moveTo point on arc, based on the angle and boundingrect)

Paths can be outlined, creating another path.
Also: intersection (&), union (|) or substraction.
In the end a path can only use 1 pen and 1 brush.
Translation and matrix mapping can also be done.

=end
  class PathItem < GraphicsItem

      # API compatible with Qt::PainterPath.
      # Actually we duplicate code since Qt::PainterPath already has internal elements.
      # However, there is no API to make changes to it, nor to filter elements.
      # PathBuilder makes it possible to create active vertices on the path, that
      # can be moved by the user, or animated.
      class PathBuilder

          # A single vertex can be usefull to designate a nonsmooth part.
          class Vertex
            private
              def initialize x = 0, y = 0, kind = :sharp, c_prev = nil, c_next = nil
                @x, @y, @kind = x, y, kind
                # if smooth it has two additional controlpoints
                @c_prev, @c_next = c_prev, c_next
              end

              def self.normalize(x, y)
                len = Math::hypot(x, y)
                return x, y if len <= 0.000_000_1 || len.nan?
                [x / len, y / len] #.tap{|p|tag "normalize(#{x}, #{y}) -> (#{p.inspect})"}
              end

            public

              def smooth?
#                 @c_prev || @c_next || @kind == :smooth
                @kind == :smooth
              end

              def endpoint?
                @kind == :end || @kind == :curve_end
              end

              def startpoint?
                @kind == :start
              end

              attr :x, :y

              def v
                return x, y
              end

              def pos= x, y = nil
                if y
                  @x, @y = x, y
                else
                  @x, @y = x
                end
              end

              def setPosAndKind x, y, kind
                @x, @y, @kind = x, y, kind
              end

              def auto_smooth prev_v, next_v, tension
                nx, ny = next_v.x - x, next_v.y - y
                px, py = prev_v.x - x, prev_v.y - y
                len_next = Math::hypot(nx, ny)
                len_prev = Math::hypot(px, py)
#                 tag "v=(#@x,#@y), p=(#{px},#{py})(len:#{len_prev}), n=(#{nx},#{ny})(len:#{len_next})"
                if len_next > 0.000_000_1 && len_prev > 0.000_000_1
                  d = len_prev / len_next
                  #// "dir" is an unit vector perpendicular to the bisector of the angle created
                  #// by the previous node, this auto node and the next node.
                  dx, dy = Vertex::normalize(d * nx - px, d * ny - py)
                  #                   // Handle lengths are equal to 1/3 of the distance from the adjacent node.
                  len_prev *= 0.333_333_333_333 * tension
                  len_next *= 0.333_333_333_333 * tension
                  @c_prev = @x - dx * len_prev, @y - dy * len_prev
                  @c_next = @x + dx * len_next, @y + dy * len_next
                else
                  @c_prev = @c_next = @x, @y
                end
              end # auto_smooth

              attr_accessor :c_prev, :c_next
              attr :kind

              def kind= aKind
                @kind = aKind unless @kind == :curve_end || @kind == :curve_start
              end

              def createDebugController qparent
                Qt::GraphicsEllipseItem.new(@x - 4, @y - 4, 8, 8, qparent)
                Qt::GraphicsLineItem.new(@x, @y, *@c_prev, qparent) if @c_prev
                Qt::GraphicsLineItem.new(@x, @y, *@c_next, qparent) if @c_next
              end
          end # class Vertex

          # these are pseudo closed paths. They have no influence on vertexlists
          # and leave the endpoint at the last point drawn. But it would be wise to
          # start the next segment with a moveTo.
          class Rectangle
          end

          class Ellipse
          end

          class RoundedRectangle
          end

          class Region
          end

          class Text
          end

        private # PathBuilder methods

=begin
  subpaths are handled ambiguously by Qt.  Since closeSubpath always adds a straight line
  it is pretty useless for curves.
  So curves need one vertex extra, the endvertex is the same as the first one.
  See example:

      QPainterPath path;
      path.addRect(20, 20, 60, 60);

      path.moveTo(0, 0);
      path.cubicTo(99, 0,  50, 50,  99, 99);
      path.cubicTo(0, 99,  50, 50,  0, 0);

   The 0,0 vertex is twice in the path.
   If we make those vertices 'active' it would immediately show up.

   smooth p1, p2, p3

   is a moveTo p1, then cubicTo p2 and cubicTo p3. Since p1 and p3 are endpoints the controlpoints
   are p1 and p3 themselves.

   smooth p1, p2, p3, :close

   :close is a lineTo p1, and p1 will not be smooth, and neither will p3
   moveTo p1, cubicTo p2, cubicTo p3, lineTo p1

   smooth p1, p2, p3, :smoothclose
   moveTo p1, cubicTo p2, cubicTo p3, cubicTo p1
   That last vertex (p1) does not count as being on the path. So the vertices are p1, p2 and p3.
   But both p1 and p3 are now smooth.

   line p1, p2, smooth p3, :close
   When a line connects to a smooth curve the curve bit is semismooth near the endpoints.
   That is we smooth the node, but there is only one handle to set.

   smooth p1, p2, p3, p1
   To get a 2 points smooth curve. At p1 the curve is not smooth, since it is twice an
   endpoint. But this is ugly. I must be able to say that a path is truly closed.

   vertex p1, smooth p2, p3, :close

   I think the rules must bend a little to make it more consistent.
   The vertices mentioned in a line expression are never smooth.
   Those mentioned in a smooth are ALL smooth.
   This implies :smoothclose becomes DEPRECATED. It is meaningless

   vertex p1, smooth p2, p3, :close

   p1 will not be smooth but p2 and p3 are. Nevertheless there are 3 cubics.

   line p1, p2, smooth p3, :close

   the segment p2-p3 must be a cubicTo(p2,p2, c3,p3)

   This also means that adding nodes may change the last one.

   Basicly we add vertices and these can be marked:
      - start(point). Counts as sharp,
      - end(point).  May be absent if subpath closes. Endpoints do not appear in the 'each_vertex' list
                   Counts as sharp.
      - sharp. as opposed to smooth
      - smooth.

   Using this scheme it is possible to add lines, moves etc...
   To avoid changing classes this just becomes a field of Vertex itself.
   The path can then be easily generated from this.

   Starting and ending is something else. It must be since line p1, p2
   is supposed to be different then smooth p1, p2.
   No, not really. endpoints cannot be smooth. And endpoints and starting points differ too.

   But the status may change.
   If I start line(p1,p2) and if I add p1 as :start, then how can I see the difference
   with smooth(p1,p2)? It seems we must delay setting :start and :end until we
   get a moveTo! If we get a :close we need not do anything after all!


   smooth p1, p2 is meaningless. However:

    line p1, p2, smooth p3, line p4

   is possible. Although a better syntax would be

    line p1, p2, smoothTo p3, lineTo p4

   What's the use of 'line' anyway.
   I would like to say that 'smooth' is a property of a vertex, and that paths are lists
   of vertices.  line v1, v2... just expresses the non-smoothness.
   But then [v1, v2] would be a better notation.
   Get into trouble with

    invalid syntax
      [v1, v2 smooth s3, s4  v5, v6 ]

    Then this:
      [v1, v2]
      smooth s3, s4
      [v5, v6]

   [] will not work properly, obviously. Stupid idea.

   Let's stick to line and smooth for the time being
=end
          def initialize item
            super()
            @smooths_present = false
            @paths = []  # of subpaths
            @paths << (@currentpath = [Vertex.new])
            # lower tension (up to 0.0) cause shorter controlpoint-lines
            # 1.0 fits a length of 1/3 of the in- and outgoing segments.
            # With 0.0 we get spiked points and basicly no roundness
            # The higher the tension the harder the edges are pulled outwards.
            @tension = 1.0
          end

           # at this stage there is no meaning in :smooth anymore.
          def connectToPrev qpath, vertex, prev
#             tag "connect #{prev} with #{vertex}"
            # special case for invisible start and end segment
            return if vertex.kind == :curve_end
            if prev.kind == :curve_start
              qpath.moveTo vertex.x, vertex.y
              return
            end
            if prev.c_next
              if vertex.c_prev
#                 tag "GEN: cubicTo #{vertex.x}, #{vertex.y} (c1=#{prev.c_next.inspect},c2=#{vertex.c_prev.inspect},q)"
                qpath.cubicTo(*prev.c_next, *vertex.c_prev, vertex.x, vertex.y)
              else
                qpath.cubicTo(*prev.c_next, vertex.x, vertex.y, vertex.x, vertex.y)
              end
            elsif vertex.c_prev
              qpath.cubicTo(prev.x, prev.y, *vertex.c_prev, vertex.x, vertex.y)
            else
#               tag "GEN: lineTo #{vertex.x}, #{vertex.y}"
              qpath.lineTo(vertex.x, vertex.y)
            end
          end

        public # PathBuilder methods

          def build
#             tag "building #{@paths.length} paths"
            moveTo 0, 0 if @currentpath.length > 1              # this will set :start + :end tags
            # calculate smooths now.
            @smooths_present and
              @paths.each do |path|
                break if (n = path.length) == 1 # which can only be the last one
                path.each_with_index do |vertex, i|
                  case vertex.kind
                  when :end, :curve_end then vertex.c_prev = vertex.v if path[(i - 1) % n].kind == :smooth
                  when :start, :curve_start then vertex.c_next = vertex.v if path[(i + 1) % n].kind == :smooth
                  when :smooth
                    vertex.auto_smooth(path[(i - 1)  % n], path[(i + 1) % n], @tension)
                  end
                end
              end
            qpath = Qt::PainterPath.new
            @paths.each do |path|
#               tag "path #{path.inspect}"
              break if path.length == 1 # which can only be the last one
#               tag "building path #{path.inspect}"
              prev = path.last
#               tag "GEN: moveTo #{path.first.x}, #{path.first.y}"
              qpath.moveTo((p0 = path.first).x, p0.y)
              prev = nil
              path.each do |vertex|
#                 tag "inspecting vertex #{vertex.x},#{vertex.y}"
                connectToPrev qpath, vertex, prev if prev
                prev = vertex
              end
              # at this point 'prev' has become the last vertex.
                # this may create a lineTo which would also be done by closeSubpath
              connectToPrev(qpath, p0, prev) unless prev.endpoint?
            end
            qpath
          end

          def moveTo x, y, kind = :sharp
            if @currentpath.length == 1 # previous move
              @currentpath.first.setPosAndKind(x, y, kind)
            else
#               tag "moveTo, set :start + :end"
              @currentpath.first.kind = :start # the endpoints are not connected
              @currentpath.last.kind = :end
              @paths << (@currentpath = [Vertex.new(x, y, kind)])
            end
          end

          def lineTo x, y
#             tag "lineTo #{x}, #{y}, extending currentpath: #{@currentpath.inspect}"
            @currentpath << Vertex.new(x, y)
          end

          def closeSubpath
#             tag "closeSubpath, #currentpath= #{@currentpath.length}"
            @paths << (@currentpath = [Vertex.new]) if @currentpath.length > 1
          end

          def smoothTo x, y
            @smooths_present = true
            @currentpath << Vertex.new(x, y, :smooth)
          end

          def bezierTo c1x, c1y, c2x, c2y, qx, qy
            @currentpath.last.c_next = c1x, c1y
            @currentpath << (v = Vertex.new(qx, qy, :bezier))
            v.c_prev = c2x, c2y
          end

          def each_vertex
            return to_enum(:each_vertex) unless block_given?
            @paths.each do |path|
              return if path.length == 1
              path.each do |vertex|
  #             tag "el.vertex = (#{el.x}, #{el.y})"
                yield(vertex) unless vertex.endpoint?
              end
            end
          end

          # this means we only did the move.
          # true initially, after a moveTo or a closeSubpath.
#           def firstnode?
#             @currentpath.empty?
#           end

          def [](index)
            @paths.each do |path|
              path.each do |vertex|
  #             tag "el.vertex = (#{el.x}, #{el.y})"
                return vertex if (index -= 1) < 0
              end
            end
          end

          def last
            @currentpath.last
          end

          def first
            @currentpath.first
          end

          attr_accessor :tension

      end # class PathBuilder

    private # PathItem methods
      def initialize parent, qtc
        super
        startPath
      end

      def startPath
        @path = PathBuilder.new(self)
      end

      def tension value = nil, &block
        case value
        when nil, Hash, Proc then DynamicAttribute.new(self, :tension, Float).setup(value, &block)
        else self.tension = value
        end
      end

      def tension= value
        unless @path.tension == value
          @path.tension = value
          assignQPath
        end
      end

      def closeSubpath
        @path.closeSubpath
      end

=begin
      if you use two lines, it's the same as one. Or you must close
      the first one explicitely
              line x, y
              line x2, y2
       Same as         line x,y, x2,y2

this is madness.

The names are bad.

moveto lineto smoothto is much better.

=end
      def lineto *args
        args.each_slice(2) do |x, y|
          return closeSubpath if x == :close
          @path.lineTo(x, y)
        end
      end

      def moveto x, y, kind = :sharp
        @path.moveTo x, y, kind
      end

      def line x, y, *args
        moveto x, y
        lineto *args
      end

      # adds a triangle, requiring 3 points
      def triangle x1,y1, x2,y2, x3,y3
        line x1,y1, x2,y2, x3,y3, :close
      end

      # at least six points are required, point 4 is attached to 2 and 3,
      # 5 to 3 and 4, 6 to 4 and 5, and so on.
      # You can pass x0,y0, x1, y1, x2, y2...
      # OR [x0,y0], [x1,y1], [x2,y2]....
      # OR Qt::PointF's
      # OR an enumerator that enumerates tuples x,y
      def triangle_strip *args
        p = q = nil
        case args[0]
        when Enumerator
#           tag "Enumerator, must iterate tuples of 2 then"
          args[0].each do |r|
#             tag "r = #{r.inspect}, line #{p.inspect},#{q.inspect},#{r.inspect},:close" if p
            line *p, *q, *r, :close if p
            p, q = q, r
          end
        when Array, Qt::PointF
          args.each do |r|
            line p, q, r, :close if p
            p, q = q, r
          end
        else
          args.each_slice(2) do |x, y|
            line *p, *q, x, y, :close if p
            p, *q = q, x, y
          end
        end
      end

      def triangle_fan x1, y1, x2, y2, *args
        p0 = x1, y1
        q = x2, y2
        args.each_slice(2) do |x, y|
          line *p0, *q, x, y, :close
          q = x, y
        end
      end

      # quad in the sense of 4 vertices, not a quadratic arc...
      def quad x1,y1, x2,y2, x3,y3, x4,y4
        line x1,y1, x2,y2, x3,y3, x4,y4, :close
      end

      def quad_strip xl1,yl1, xr1,yr1, *args
        pl = xl1, yl1
        pr = xr1, yr1
        args.each_slice(4) do |xl, yl, xr, yr|
          line *pl, *pr, xr, yr, xl, yl, :close
          pl = xl, yl
          pr = xr, yr
        end
      end

      # slightly problematic...
      # we must delay a single node (prov. we use cubics, with quads it cannot be done)
      # This may turn ugly in which case ActivePath has a solution.
      # build an internal path first, then convert it to Qt::PainterPath.
      # and we have full control.
      # if the path was not closed the first node will be smooth.
      def smoothto *args
        args.each_slice(2) do |x, y|
          return closeSubpath if x == :close
          @path.smoothTo(x, y)
        end
      end

      def smooth x, y, *args
        moveto x, y, :smooth
        smoothto *args
      end

      def curve *args
#         tag "Calling smooth(#{args.inspect})"
        smooth *args
#         tag "set :curve_start + :curve_end"
        @path.first.kind = :curve_start
        @path.last.kind = :curve_end
      end

      # args must have a size that is a multiple of 6
      def bezierto *args
        args.each_slice(6) do |a| # } # c1x, c1y, c2x, c2y, qx, qy|
          @path.bezierTo(*a)
        end
      end

      # 8 args + extra tuples of 6
      def bezier x, y, *args
        moveto x,y
        bezierto *args
      end

      # called by postSetup, should only be called once
      def assignQPath
        @qtc.path = @path.build
#         tag "path: #{@path.each_vertex { |v| v.inspect }}"
      end

      alias :endPath :assignQPath

    public

      def postSetup
        super
        assignQPath
      end

      def self.new_qt_implementor qt_implementor_class, parent, qt_parent
        qt_implementor_class.new # no parent ?? why is this ??
#         res.pen, res.brush = parent.pen, parent.brush
#         res
      end

  end # PathItem

  class QGraphicsPathItem < Qt::GraphicsPathItem
    include QGraphicsItemHackContext
  end

  createInstantiator File.basename(__FILE__, '.rb'), QGraphicsPathItem, PathItem
#   tag "test for Scene#circle"
#   raise ReformError, 'oh no' unless Scene.private_method_defined?(:circle)

end # Reform