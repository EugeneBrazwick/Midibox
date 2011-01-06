module Reform

  require 'reform/graphicsitem'

  class BezierCurve < GraphicsItem

    private
      def initialize parent, qtc
        super
        @c1 = @c2 = @p2 = @p1 = Qt::PointF.new(0, 0)
      end

      # macro
      def self.def_coord_meth name, varname = nil
        varname ||= ('@' + name.to_s).to_sym
        define_method name do |x = nil, y = nil|
          return instance_variable_get(varname) unless x
          instance_variable_set(varname, case x
            when Array then Qt::PointF.new(*x)
            when Qt::PointF then x
            else Qt::PointF.new(x, y)
            end)
#           tag "calling assignQPath, self = #{self}"
          assignQPath
        end
      end

      def_coord_meth :from, :@p1
      def_coord_meth :to, :@p2
      def_coord_meth :c1
      def_coord_meth :c2

      def controlpoints c1, c2 = nil
        c1, c2 = c1 if Array === c1
        @c1= case c1
        when Array then Qt::PointF.new(*c1)
        else c1
        end
        @c2= case c2
        when Array then Qt::PointF.new(*c2)
        else c2
        end
        assignQPath
      end

      def assignQPath
#         tag "p1 = #{@p1.inspect}"
        path = Qt::PainterPath.new(@p1)
#         tag "calling cubicTo #@c1, #@c2, #@p2"
        path.cubicTo @c1, @c2, @p2
        @qtc.path = path
      end

    public

      # override
      def postSetup
        super
        assignQPath
      end

  end

  class QBezierCurve < Qt::GraphicsPathItem
    include QGraphicsItemHackContext
  end

  createInstantiator File.basename(__FILE__, '.rb'), QBezierCurve, BezierCurve

end # module Reform