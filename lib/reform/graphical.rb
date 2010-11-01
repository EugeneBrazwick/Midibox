
# Copyright (c) 2010 Eugene Brazwick

require 'reform/control'

module Reform

  # this module contains generated and other 'brush' and 'pen' constructors.
  # these will be used when rendering shapes on a graphicsitem, canvas or scene.
  module Graphical
    extend Graphical

    class Brush < Control
        include Graphical
      private
        def initialize
          super(nil, Qt::Brush.new)
        end

        # makes it a solid brush
        def color *args
          @qtc = make_brush(make_color(*args))
        end

      public
        def name aName = nil # not supported since Qt::Brush is not a Qt::Object at all. And we already index them too
        end

      end # class Brush

      class Pen < Control
        include Graphical
        def initialize
          super(nil, Qt::Pen.new)
        end

        def color *args
          @qtc = make_pen(make_color(*args))
        end

        define_simple_setter :widthF

#         # width can be used with a float. If 0.0 the pen is cosmetic
        def width value
          case value
          when Fixnum then @qtc.width = value
          else @qtc.widthF = value
          end
        end

        alias :size :width

        # make the size 1 pixel, independent of scale
        def cosmetic v_true = true
          @qtc.widthF = 0.0
        end

        JoinMap = { :miter => Qt::MiterJoin, :bevel => Qt::BevelJoin, :roundjoin => Qt::RoundJoin,
                    :round => Qt::RoundJoin }

        def joinStyle value
          value = JoinMap[value] || Qt::MiterJoin if Symbol === value
          @qtc.joinStyle = value
        end

        alias :join :joinStyle

        CapMap = { :square => Qt::SquareCap, :flat => Qt::FlatCap, :round => Qt::RoundCap,
                   :roundcap => Qt::RoundCap }

        def capStyle value
          @qtc.capStyle = Symbol === value ? CapMap[value] || Qt::FlatCap : value
        end

        StyleMap = { :solid => Qt::SolidLine, :dash => Qt::DashLine, :dot => Qt::DotLine,
                     :dashdot => Qt::DashDotLine, :dashdotdot => Qt::DashDotDotLine,
                     :custemdash => Qt::CustomDashLine }

        # example: style :roundjoin, :roundcap, :solid
        # which is the same as style :round, :solid
        def style *values
          values.each do |value|
            case value
            when Symbol
              v = JoinMap[value] and @qtc.joinStyle = v
              v = CapsMap[value] and @qtc.capStyle = v
              v = StyleMap[value] and @qtc.style = v
            else
              @qtc.style = value
            end
          end
        end

      public
        def name aName = nil
        end
      end # class Pen


  private # Graphical methods

      Qt::Color::allowX11ColorNames = true #rescue nil

        #DEPRECATED!!!! DO NOT USE
      def self.generateColorConverter name, klass, cache
        define_method name do |colorsym, *more|
          case colorsym
          when nil, false
            cache[:none] ||= klass.new(klass == Qt::Brush ? Qt::NoBrush : Qt::NoPen)
          when Symbol
            cache[colorsym] ||= klass.new(@@color[colorsym])
          else
            klass.new(make_color(colorsym, *more))
          end
        end
      end
        #DEPRECATED!!!! DO NOT USE

    public

      # index: colorsymbol, value: Qt::Brush
      @@solidbrush = {}
      @@pen = {}
    #   @@defaultpen = @@defaultbrush = nil

      # these are of class Qt::Enum
      @@color = { white: Qt::white, black: Qt::black,
        yellow: Qt::yellow, red: Qt::red, blue: Qt::blue,
        green: Qt::green, darkRed: Qt::darkRed, darkGreen: Qt::darkGreen,
        darkBlue: Qt::darkBlue, cyan: Qt::cyan, darkCyan: Qt::darkCyan, teal: Qt::darkCyan,
        magenta: Qt::magenta, darkMagenta: Qt::darkMagenta,
        darkYellow: Qt::darkYellow, brown: Qt::darkYellow,
        gray: Qt::gray, darkGray: Qt::darkGray, lightGray: Qt::lightGray,
        transparent: Qt::transparent,
        default: Qt::black
      }

      # but we remap it to Qt::Color. And we make the symbols above available as methods
      # so pens and brushes can be given a (basic) color easily.
      # IMPORTANT: do not use 'for' here since it will tie all 'sym' instances into 1 knot.
      @@color.keys.each do |sym|
    #     tag "Mapping #{@@color[sym]}"
        @@color[sym] = Qt::Color.new(@@color[sym])
    #     tag "result = Qt::Color #{@@color[sym].red} #{@@color[sym].green} #{@@color[sym].blue}"
        define_method sym do
          @@color[sym]
        end
      end

      def self.colorkeys
        @@color.keys
      end

      # returns a Qt::Color. The heart of colorknowledge on earth
      # first arg can be
      #   - symbol, like :white, These values (and these only) are cached.
      #   - Qt::Color (as is)
      #   - Qt::Brush, using its color
      #   - a String like #rgb or #rrggbb or #rrrrggggbbbb or #rgba, (and similar) or a color name
      #   - Qt::Color enum member like Qt::white
      #   - Array [r, g, b] or [r,g,b,a]
      #   - int for red, and then arg2 = greenm arg3 is blue, and arg4 is default 255 (alpha aka opaqueness)
      #         all values must be between 0 and 255
      #   - float. similar, but all values must be between 0.0 and 1.0
      def make_color colorsym, g = nil, b = nil, a = nil
#         tag "make_color(#{colorsym}, #{g}, #{b}, #{a})"
        case colorsym
    #     when Qt::Color, Qt::ConicalGradient, Qt::LinearGradient, Qt::RadialGradient then colorsym
        when Qt::Color then colorsym
        when Qt::Brush then colorsym.color
        when String
          if colorsym[0] == '#'
            case colorsym.length
            when 5
              r = Qt::Color.new(colorsym[0...-1])
              alpha = colorsym[-1, 1].hex * 17
              r.setAlpha(alpha)
            when 9
              # #rrggbbaa
              r = Qt::Color.new(colorsym[0...-2])
              alpha = colorsym[-2, 2].hex
              r.setAlpha(alpha)
            when 13
              # #rrrgggbbbaaa
              r = Qt::Color.new(colorsym[0...-3])
              alpha = colorsym[-3, 3].hex / 4096.0
              r.setAlphaF(alpha)
            when 17
              # #rrrrggggbbbbaaaa
              r = Qt::Color.new(colorsym[0...-4])
              alpha = colorsym[-4, 4].hex / 65536.0
              r.setAlphaF(alpha)
            else
              r = Qt::Color.new(colorsym)
            end
            r
          else
            Qt::Color.new(colorsym)
          end
        when Qt::Enum then Qt::Color.new(colorsym)
        when Array then Qt::Color.new(*colorsym)
        when Integer then Qt::Color.new(colorsym, g || colorsym, b || colorsym, a || 255)
        when Float then Qt::Color.new((colorsym * 255.0).floor, ((g || colorsym) * 255.0).floor,
                                      ((b || colorsym) * 255.0).floor,
                                      ((a || 1.0) * 255.0).floor)
        when Symbol then @@color[colorsym]
        else raise Error, "invalid color #{colorsym}, #{g}, #{b}, #{a}"
        end
      end

      alias :color :make_color

      generateColorConverter :color2pen, Qt::Pen, @@pen     # DEPRECATED
      generateColorConverter :color2brush, Qt::Brush, @@solidbrush # DEPRECATED

      # convert anything into a Qt::Pen
      # Examples: make_pen 12, 3,
      #           make_pen :blue
      #           make_pen blue
      # The symbol param is the only one that caches the result.
      def make_pen *args, &block
        args = args[0] if args.length <= 1
        args = args.qtc if args.respond_to?(:qtc)
        case args
        when Qt::Pen then args
        when false, :none, :nopen, :no_pen then @@pen[:none] ||= Qt::Pen.new(Qt::NoPen)
        when nil
          if block
            Pen.new.setup(nil, &block).qtc
          else
            @@pen[:none] ||= Qt::Pen.new(Qt::NoPen)
          end
        when Symbol
          col = @@color[args] or raise Error, ":#{args} is not a valid colorsymbol, use #{@@color.keys.inspect}"
          @@pen[args] ||= Qt::Pen.new(col)
        when Hash then Pen.new.setup(args, &block).qtc
        when Array then Qt::Pen.new(make_color(*args))
        when Qt::Color then Qt::Pen.new(args)
        when Qt::Brush then Qt::Pen.new(args.color)
        else Qt::Pen.new(make_color(args))
        end
      end

      # convert anything into a Qt::Brush
      def make_brush *args, &block
        args = args[0] if args.length <= 1
    #     tag "make_brush #{colorsym}, #{more.inspect}"
        args = args.qtc if args.respond_to?(:qtc)
    #     tag "colorsym = #{colorsym.inspect}"
        case args
        when Qt::Brush then args
        when false, :none, :nobrush, :no_brush then @@solidbrush[:none] ||= Qt::Brush.new(Qt::NoBrush)
        when nil
          if block
            Brush.new.setup(nil, &block).qtc
          else
            @@solidbrush[:none] ||= Qt::Brush.new(Qt::NoBrush)
          end
        when Symbol
    #       tag "locating :#{colorsym}, working through @@color #{@@color.inspect}"
          col = @@color[args] or raise Error, ":#{args} is not a valid colorsymbol, use #{@@color.keys.inspect}"
          @@solidbrush[args] ||= Qt::Brush.new(col) #) .tap{|b| tag "returning #{b}"}
        when Qt::RadialGradient, Qt::LinearGradient, Qt::ConicalGradient then Qt::Brush.new(args)
        when Hash then Brush.new.setup(args, &block).qtc
        when String
          if args[0, 7] == 'file://'
            Qt::Brush.new(Qt::Pixmap.new(args[7..-1]))
          else
            Qt::Brush.new(make_color(args))
          end
        when Array then Qt::Brush.new(make_color(*args))
        when Qt::Color then Qt::Brush.new(args)
        else Qt::Brush.new(make_color(args))
        end
      end

      # horizontal gradient, with width 'w' logical units and
      # a linear pattern of brushes or colors
      # if no brushes are given it is white to black (left to right)
      # with a single color it is that color to black (left to right)
      def gradient w, *brushes
        g = Qt::LinearGradient.new(0.0, 0.0, w, 0.0)
        brushes[0] = make_color(:white) if brushes.empty?
        brushes[1] = make_color(:black) if brushes.length < 2
        d = 1.0 / brushes.length
        j = 0.0
        brushes.each do |b|
          g.setColorAt j, make_color(b)
          j += d
        end
        Qt::Brush.new g
      end

      class Gradient < Control
        include Graphical
      private
        def initialize klass
    #       tag "Creating #{klass}"
          super nil, klass.new
        end

        def stop hash # FIXME: 1-liner
          offset = [[hash[:offset] || 0.0, 0.0].max, 1.0].min
          col = make_color(hash[:color] || :white)
          @qtc.setColorAt(offset, col)
        end

        # due to limitations in qtruby stops do not replace. They always add, so to alter the stops
        # you must create a new gradient instead...
        def stops hash
          if hash
            # using setStops is very problematic
            hash.each do |pt, col|
    #           tag "#@qtc.setColorAt(#{pt}, #{col})"
              @qtc.setColorAt(pt, make_color(col))
            end
          else
    #         tag "setColor 0000000 to fffffff"
            @qtc.setColorAt(0.0, make_color(:white)) # Qt::Color::fromRgba(0x00000000))
            @qtc.setColorAt(1.0, make_color(:black)) # Qt::Color::fromRgba(0x00ffffff))
            # AARGHH ArgumentError: Cannot handle 'const QVector<QPair<double,QColor> >&' as argument of QGradient::setStops
            #@qtc.stops = [0.0, Qt::Color::fromRgba(0x00000000)], [1.0, Qt::Color::fromRgba(0xffffffff)]]

            # AARGHH ArgumentError: Cannot handle 'const QVector<QPair<double,QColor> >&' as argument of QGradient::setStops
            #@qtc.stops = []

            # AARGHH ArgumentError: Cannot handle 'const QVector<QPair<double,QColor> >&' as argument of QGradient::setStops
            #@qtc.stops = {}

            #ArgumentError: Cannot handle 'QVector<QPair<double,QColor> >' as return-type of QGradient::stops
            #@qtc.stops.clear


            # ?????
          end
        end
      end

      class RadialGradient < Gradient
      private
        def initialize
          super Qt::RadialGradient
        end

        def center x = nil, y = nil
          return @qtc.center unless x
          x, y = x if Array === x
          @qtc.setCenter(x, y || x)
        end

        def focalPoint x = nil, y = nil
          return @qtc.focalPoint unless x
          x, y = x if Array === x
          @qtc.setFocalPoint(x, y || x)
        end

        alias :focalpoint :focalPoint

        define_simple_setter :radius

      end # class RadialGradient

      class LinearGradient < Gradient
      private
        def initialize aStart = [0,0], aStop=[100,0], colors = nil # p.e.: { 0.0=>:white, 1.0=>:black }
          super Qt::LinearGradient
          start aStart
          stop aStop
          stops colors if colors
        end

        def start x = nil, y = nil
          return @qtc.start unless x
          x, y = x if Array === x
          @qtc.setStart(x, y || x)
        end

        def stop x = nil, y = nil
          return @qtc.finalStop unless x
          x, y = x if Array === x
          @qtc.setFinalStop(x, y || x)
        end

    #     def rect
        alias :finalStop :stop

      end # class LinearGradient

      def radialgradient quickyhash = nil, &block
        RadialGradient.new.setup(quickyhash, &block)
      end

      def lineargradient quickyhash = nil, &block
    #     tag "lineargradient.new.setup(#{quickyhash}, #{block})"
        LinearGradient.new.setup(quickyhash, &block)
      end

      def defaultBrush
        @@defaultbrush ||= make_brush(:white)
      end

      def defaultPen
        @@defaultpen ||= make_pen(:black)
      end

      def noPen
        @@nopen ||= make_pen(:none)
      end

      def noBrush
        @@nobrush ||= make_brush(:none)
      end

      def brushRecipy &aProc
        aProc.call
      end

=begin
      Example
        define {
          paintgroup bubble { circle }
        }
        bubble
=end
      def self.registerGroupMacro scene, name, macro
        name = name.to_sym
        define_method name do |quickyhash = nil, &block|
          # self is the object the item must be added to...
          macro.exec(self, quickyhash, &block)
        end
      end

  end # Graphical

end # Reform