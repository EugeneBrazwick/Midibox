
module Reform

  require_relative 'shadewidget'

  # The gradienteditor combines 4 shaders to create a mapping from pixeldistance to an argb
  class GradientEditor < Widget
    private
      def initialize parent, qtc
        super
        connect(@qtc, SIGNAL('gradientStopsChanged()'), self) do
          rfRescue do
            tag "changed, assign '#{@qtc.stops}' to models property cid=#{connector}, effectiveModel=#{effectiveModel}"
            model = effectiveModel and cid = connector and model.model_apply_setter(cid, @qtc.stops)
          end
        end
      end

      define_simple_setter :gradientStops

      alias :stops :gradientStops

    public

      #override
      def updateModel model, options = nil
#       tag "connectModel #{model.inspect}, cid=#{connector}"
        cid = connector and
          if model && model.model_getter?(cid)
            @qtc.stops = model.model_apply_getter(cid)
#             @qtc.readOnly = !model.setter?(cid)
          else
            @qtc.stops = nil # aka 'apply default'
          end
        super
      end
  end # class GradientEditor

  class QGradientEditor < QWidget
    private
      def initialize parent
        super
        vbox = Qt::VBoxLayout.new(self);
        vbox.setSpacing(1);
        vbox.setMargin(1);

        @red_shade = QShadeWidget.new(self, :red);
        @green_shade = QShadeWidget.new(self, :green);
        @blue_shade = QShadeWidget.new(self, :blue)
        @alpha_shade = QShadeWidget.new self
        vbox.addWidget(@red_shade);
        vbox.addWidget(@green_shade);
        vbox.addWidget(@blue_shade);
        vbox.addWidget(@alpha_shade);

        connect(@red_shade, SIGNAL('colorsChanged()')) { pointsUpdated }
        connect(@green_shade, SIGNAL('colorsChanged()')) { pointsUpdated }
        connect(@blue_shade, SIGNAL('colorsChanged()')) { pointsUpdated }
        connect(@alpha_shade, SIGNAL('colorsChanged()')) { pointsUpdated }

      end

      def self.set_shade_points(points, shade)
        (hps = shade.hoverPoints).points = points
        hps.setPointLock(0, HoverPoints::LockToLeft);
        hps.setPointLock(points.length() - 1, HoverPoints::LockToRight);
        shade.update();
      end

    public
      def pointsUpdated
        w = @alpha_shade.width();
        stops = {}
        points = (@red_shade.points() || []) + (@green_shade.points() || []) +
                 (@blue_shade.points() || []) + (@alpha_shade.points() || [])
        points.sort! { |p1, p2| p1.x <=> p2.x }
        points.each_with_index do |p, i|
          x = points[i].x.to_i
          next if i < points.length - 1 && x == points[i + 1].x.to_i
          return if x / w > 1
          color = Qt::Color.new((0x00ff0000 & @red_shade.colorAt(x)) >> 16,
                                (0x0000ff00 & @green_shade.colorAt(x)) >> 8,
                                (0x000000ff & @blue_shade.colorAt(x)),
                                (0xff000000 & @alpha_shade.colorAt(x)) >> 24);

          stops[x / w] = color
        end
        @alpha_shade.gradientStops = stops
        gradientStopsChanged();
      end

      def gradientStops
        @alpha_shade.gradientStops
      end

      def gradientStops= stops
        stops ||= {0.00=>Qt::Color::fromRgba(0x00000000),  1.00=>Qt::Color::fromRgba(0xffffffff) }

        pts_red = []
        pts_green = []
        pts_blue = []
        pts_alpha = []

        h_red = @red_shade.height();
        h_green = @green_shade.height();
        h_blue = @blue_shade.height();
        h_alpha = @alpha_shade.height();

        stops.each do |pos, c|
          pts_red << Qt::PointF.new(pos * @red_shade.width(), h_red - c.red * h_red / 255);
          pts_green << Qt::PointF.new(pos * @green_shade.width(), h_green - c.green * h_green / 255);
          pts_blue << Qt::PointF.new(pos * @blue_shade.width(), h_blue - c.blue * h_blue / 255);
          pts_alpha << Qt::PointF.new(pos * @alpha_shade.width(), h_alpha - c.alpha * h_alpha / 255);
        end

        QGradientEditor.set_shade_points(pts_red, @red_shade);
        QGradientEditor.set_shade_points(pts_green, @green_shade);
        QGradientEditor.set_shade_points(pts_blue, @blue_shade);
        QGradientEditor.set_shade_points(pts_alpha, @alpha_shade);
      end

      slots 'pointsUpdated()'
      #signals 'gradientStopsChanged(const QGradientStops &)'           qtruby4.4.2 cannot handle this
      signals 'gradientStopsChanged()'

      alias :stops :gradientStops
      alias :stops= :gradientStops=
  end # class

  createInstantiator File.basename(__FILE__, '.rb'), QGradientEditor, GradientEditor

end # module