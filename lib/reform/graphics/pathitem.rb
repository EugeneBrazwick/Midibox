
require_relative '../graphicsitem'

module R::Qt

  class GraphicsPathItem < AbstractGraphicsShapeItem

      # API compatible with PainterPath.
      # Actually we duplicate code since PainterPath already has internal elements.
      # However, there is no API to make changes to it, nor to filter elements.
      # PathBuilder makes it possible to create active vertices on the path, that
      # can be moved by the user, or animated.
      class Builder

          # A single vertex can be usefull to designate a nonsmooth part.
          class Vertex
            private # methods of Vertex
              def initialize x = 0, y = 0, kind = :sharp, c_prev = nil, c_next = nil
                @x, @y, @kind = x, y, kind
                # if smooth it has two additional controlpoints
                @c_prev, @c_next = c_prev, c_next
              end # initialize

              def self.normalize x, y
                len = Math::hypot x, y
                return x, y if len <= 0.000_000_1 || len.nan?
                [x / len, y / len] #.tap{|p|tag "normalize(#{x}, #{y}) -> (#{p.inspect})"}
              end # normalize

            public # methods of Vertex

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
                [x, y]
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
                len_next = Math::hypot nx, ny
                len_prev = Math::hypot px, py
#                 tag "v=(#@x,#@y), p=(#{px},#{py})(len:#{len_prev}), n=(#{nx},#{ny})(len:#{len_next})"
                if len_next > 0.000_000_1 && len_prev > 0.000_000_1
                  d = len_prev / len_next
                  #// "dir" is an unit vector perpendicular to the bisector of the angle created
                  #// by the previous node, this auto node and the next node.
                  dx, dy = Vertex::normalize d * nx - px, d * ny - py
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
                GraphicsEllipseItem.new(@x - 4, @y - 4, 8, 8, qparent)
                GraphicsLineItem.new(@x, @y, *@c_prev, qparent) if @c_prev
                GraphicsLineItem.new(@x, @y, *@c_next, qparent) if @c_next
              end
          end # class Vertex

          # these are pseudo closed paths. They have no influence on vertexlists
          # and leave the endpoint at the last point drawn. But it would be wise to
          # start the next segment with a moveTo.
          class Rectangle; end
          class Ellipse; end
	  class RoundedRectangle; end
	  class Region; end
	  class Text; end

        private # Builder methods

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
          end # initialize

           # at this stage there is no meaning in :smooth anymore.
          def connectToPrev qpath, vertex, prev
#             tag "connect #{prev} with #{vertex}"
            # special case for invisible start and end segment
            return if vertex.kind == :curve_end
	    return qpath.moveTo vertex.x, vertex.y if prev.kind == :curve_start
            if prev.c_next
              if vertex.c_prev
#                 tag "GEN: cubicTo #{vertex.x}, #{vertex.y} (c1=#{prev.c_next.inspect},c2=#{vertex.c_prev.inspect},q)"
                qpath.cubicTo(*prev.c_next, *vertex.c_prev, vertex.x, vertex.y)
              else
                qpath.cubicTo(*prev.c_next, vertex.x, vertex.y, vertex.x, vertex.y)
              end
            elsif vertex.c_prev
              qpath.cubicTo prev.x, prev.y, *vertex.c_prev, vertex.x, vertex.y
            else
#               tag "GEN: lineTo #{vertex.x}, #{vertex.y}"
              qpath.lineTo vertex.x, vertex.y
            end 
          end # connectToPrev

        public # Builder methods

	  # the return value is assigned to the QGraphicsPathItem.path.
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
            qpath = PainterPath.new
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
          end # build

          def moveTo x, y, kind = :sharp
            if @currentpath.length == 1 # previous move
              @currentpath.first.setPosAndKind(x, y, kind)
            else
#               tag "moveTo, set :start + :end"
              @currentpath.first.kind = :start # the endpoints are not connected
              @currentpath.last.kind = :end
              @paths << (@currentpath = [Vertex.new(x, y, kind)])
            end
          end # moveTo

          def lineTo x, y
#             tag "lineTo #{x}, #{y}, extending currentpath: #{@currentpath.inspect}"
            @currentpath << Vertex.new(x, y)
          end # lineTo

          def closeSubpath
#             tag "closeSubpath, #currentpath= #{@currentpath.length}"
            @paths << (@currentpath = [Vertex.new]) if @currentpath.length > 1
          end # closeSubpath

          def smoothTo x, y
            @smooths_present = true
            @currentpath << Vertex.new(x, y, :smooth)
          end # smoothTo

          def bezierTo c1x, c1y, c2x, c2y, qx, qy
            @currentpath.last.c_next = c1x, c1y
            @currentpath << (v = Vertex.new(qx, qy, :bezier))
            v.c_prev = c2x, c2y
          end # bezierTo

          def each_vertex
            return to_enum(:each_vertex) unless block_given?
            @paths.each do |path|
              return if path.length == 1
              path.each do |vertex|
  #             tag "el.vertex = (#{el.x}, #{el.y})"
                yield vertex  unless vertex.endpoint?
              end
            end
          end # each_vertex

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

      end # class Builder

    private # methods of GraphicsPathItem
      def initialize *args
	super
	startPath
      end

      def startPath
        @path = Builder.new self
      end

      def tension_get
	@path.tension
      end

      def tension= value
        unless @path.tension == value
          @path.tension = value
          assignQPath
        end
      end

      attr_dynamic Float, :tension

      def closeSubpath
        @path.closeSubpath
      end

      ## :call-seq: lineto x1,y1 [, x2,y2, .... [, :close]]
      def lineto *args
        args.flatten.each_slice(2) do |x, y|
          return closeSubpath if x == :close
          @path.lineTo x, y
        end
      end

      ## kind can be :sharp or :curve
      def moveto x, y, kind = :sharp
        @path.moveTo x, y, kind
      end

      ## :call-seq: line x1,y1, x2,y2 [, x3,y3, .... [, :close]]
      def line x, y, *args
        moveto x, y
        lineto *args
      end

      ## adds a triangle, requiring 3 points
      def triangle x1,y1, x2,y2, x3,y3
        line x1,y1, x2,y2, x3,y3, :close
      end

      ## at least six points are required, point 4 is attached to 2 and 3,
      # 5 to 3 and 4, 6 to 4 and 5, and so on.
      #
      #	:call-seq: 
      #	    triangle_strip x0,y0, x1, y1, x2, y2 [,...]
      #	    triangle_strip [x0,y0], [x1,y1], [x2,y2]....
      #	    triangle_strip p1, p2, p3  
      #	    triangle_strip enumerator
      def triangle_strip *args
        p = q = nil
        case args[0]
        when Enumerator
	  raise ArgumentError, "bad argument count" unless args.length == 1
#           tag "Enumerator, must iterate tuples of 2 then"
          args[0].each do |r|
#             tag "r = #{r.inspect}, line #{p.inspect},#{q.inspect},#{r.inspect},:close" if p
            line *p, *q, *r, :close if p
            p, q = q, r
          end
        when Array, PointF
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

      # this has inconsistent argument parsing. But it's more like a toy anyway.
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
      # build an internal path first, then convert it to PainterPath.
      # and we have full control.
      # if the path was not closed the first node will be smooth.
      def smoothto *args
        args.each_slice(2) do |x, y|
          return closeSubpath if x == :close
          @path.smoothTo x, y
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
        moveto x, y
        bezierto(*args)
      end

      # called by setup
      def assignQPath
        self.path = @path.build
#         tag "path: #{@path.each_vertex { |v| v.inspect }}"
      end

      alias :endPath :assignQPath

    public

      #override
      def setup hash = nil, &initblock
        super
        assignQPath
      end


  end # class GraphicsPathItem

  class BezierCurve < GraphicsPathItem
    public # methods of BezierCurve
      attr_dynamic PointF, :from, :to, :c1, :c2
  end

  Reform.createInstantiator __FILE__, GraphicsPathItem
end # module R::Qt

