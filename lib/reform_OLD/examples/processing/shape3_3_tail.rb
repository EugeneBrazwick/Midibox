
=begin

Copyright (c) 2011 Eugene Brazwick

The previous example was crap.

This example is crap too.
I fear a mathematician is required urgently...

It took me quite some
time to figure out why combining the rotation+scale+translate in a single matrix did
not work. My idea was that every step in the tail creates the exact same quad, except
the next one is slightly smaller. But this would be wrong since the original example
always makes pieces of 8 (@resolution) long.

So relatively to the midpoint of the last line, translate 8 down, then scale horizontally,
and then rotate around 0,0 by @angle degrees.
If I use that matrix the scaling and rotation start to mix up and the result is not 'pointy'
anymore.

Also with 3 very simple shapes regeneration takes ages and ages...
How can that be so slow???

It is also obvious that changing 'x' changes the shape. That is not at all required.
The shape does not need a starting point and angle, we can use transformation on
the shape to get it for free.

=end

require 'reform/app'
require 'reform/graphics/graphicspath'

module Reform

  class Tail < PathItem
    private

      def initialize parent, qtc
        super
        @units = 6
        @from, @to = Qt::PointF.new(-@units / 2, 0), Qt::PointF.new(@units / 2, 0)
        @angle, @resolution = 0, 8
        @use_quads = true
      end

      define_setter Qt::PointF, :from, :to
      define_setter Float, :resolution, :angle
      define_setter Integer, :units
      define_setter FalseClass, :use_quads

      def extend_path l, r, accum_matrix, transform, accum_scaler, scaler, n
        # our caller ended in 'r', and will continue the drawing at 'l'
        l2, r2 = accum_matrix.map(accum_scaler.map(@from)), accum_matrix.map(accum_scaler.map(@to))
#         tag "l2=#{l2.inspect}, r2=#{r2.inspect}, distance = #{(l2 - r2).length}, angle now #{(r2-l2).angle}"
        if @use_quads
          quad l.x,l.y, r.x,r.y, r2.x,r2.y, l2.x,l2.y
          extend_path l2, r2, accum_matrix *= transform, transform, accum_scaler *= scaler, scaler, n - 1 if n > 1
        else
          lineto r2.x, r2.y
          extend_path l2, r2, accum_matrix *= transform, transform, accum_scaler *= scaler, scaler, n - 1 if n > 1
          # the previous line ended the drawing at 'l2'
          lineto l.x, l.y
#           tag "lineto #{l.x}, #{l.y}"
        end
      end

      def redo_shaping
        startPath
        line @from.x, @from.y, @to.x, @to.y # let's call it 'l' side plus the 'r' side. We end here at 'r'.
#         tag "LINE = (#{@from.x},#{@from.y}) - (#{@to.x},#{@to.y})"
        matrix = Qt::Transform.new
        # translate must be the normal vector of @from-@to.
        l = Qt::LineF.new(@from, @to)
        start_angle = l.angle # ccw
#         tag "@reso = #@resolution, @angle= #@angle ang = #{l.normalVector.angle}"
        # IMPORTANT align the matrix with the midpoint of the segment as 0, 0
        midx, midy = (@from.x + @to.x) / 2, (@from.y + @to.y) / 2
        matrix.translate(midx, midy).rotate(-start_angle)
        # aligned with the line-segment, after rotating ccw

        # scale ** units should be l.length
        units = [1, @units].max
        required_downscale = 1.0 / (l.length ** (1.0 / units))
#         tag "units = #{units} (#@units), req.ds = #{required_downscale}, start_angle = #{start_angle}"

        # translate and scale may mix, but do not rotate until both are done!
        matrix.translate(0, @resolution).rotate(@angle)

        # now move back to the item coordsystem by undoing the initial aligning:
        matrix.rotate(start_angle).translate(-midx, -midy)

        # same for the scaler
        scalematrix = Qt::Transform.new
        scalematrix.translate(midx, midy).rotate(-start_angle).scale(required_downscale, 1.0)
                   .rotate(start_angle).translate(-midx, -midy)
#         matrix.translate(-@from)
        # our matrix is ready to rumble!
        extend_path @from, @to, Qt::Transform.new(matrix), matrix, Qt::Transform.new(scalematrix), scalematrix, units
        # this ended the drawing at '@from'. OK.
        endPath
      end

      def self.make_setters *names
        names.each do |name|
          name = name.to_s
#           assigner = (name + '=').to_sym
          define_method name + '=' do |val|
            instance_variable_set('@' + name, val)
            redo_shaping
          end
        end
      end

      def apply_dynamic_getter name
        instance_variable_get('@' + name.to_s)
      end

    public

      make_setters :from, :to, :resolution, :angle, :units, :use_quads

  end

  registerKlass GraphicsItem, :tail, QGraphicsPathItem, Tail

end # Reform


Reform::app {
  form {
    struct x: 20, units: 7, angle100: -12
    hbox {
      hbox {
        vbox {
          label text: 'X'
          slider orientation: :vertical, range: 0..100, connector: :x
        }
        vbox {
          label text: 'Units'
          slider orientation: :vertical, range: 1..16, connector: :units
        }
        vbox {
          label text: 'Angle'
          # Note that the range is integers only. Weird?
          slider orientation: :vertical, range: [-2000, 2000], connector: :angle100
        }
        checkbox {
          text 'Use quads'
          connector :use_quads
        }
      }
      define {
        canvas_params parameters {
          area 0, 0, 100, 100
          scale 2
          background 204
        }
      }
      canvas {
        parameters :canvas_params
        tail {
          from -> data { Qt::PointF.new(data.x - data.units / 2, 0) }
          to -> data { Qt::PointF.new(data.x + data.units / 2, 0) }
#           resolution 8
          angle -> data { data.angle100 / 100.0 }
          units connector: :units
          use_quads connector: :use_quads
          brush color: -> data { data.use_quads ? white : blue }
          pen color: -> data { data.use_quads ? black : :none }
        }
      } # canvas
      canvas {
        parameters :canvas_params
        tail {
          from Qt::PointF.new(24, 10) # this is fugly....
          to Qt::PointF.new(38, 40)
          resolution 8
          angle -> data { data.angle100 / 100.0 }
          units connector: :units
          use_quads connector: :use_quads
          brush color: -> data { data.use_quads ? white : blue }
          pen color: -> data { data.use_quads ? black : :none }
        }
      } # canvas
      canvas {
        parameters :canvas_params
        tail {
          from Qt::PointF.new(84, 18)
          to Qt::PointF.new(84, 28)
          resolution 8
          angle -> data { data.angle100 / 100.0 }
          units connector: :units
          use_quads connector: :use_quads
          brush color: -> data { data.use_quads ? white : blue }
          pen color: -> data { data.use_quads ? black : :none }
        }
      } # canvas
    } # hbox
  }
}
