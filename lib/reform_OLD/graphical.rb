
# Copyright (c) 2010 Eugene Brazwick

require 'reform/control'

module Qt
  class Pen
    def inspect
      "#{self}(#{color.red},#{color.green},#{color.blue}), weight=#{widthF}"
    end
  end
end

module Reform

  # this module contains generated and other 'brush' and 'pen' constructors.
  # these will be used when rendering shapes on a graphicsitem, canvas or scene.
  module Graphical
    extend Graphical

=begin
I believe 'brush' and 'pen' can become plugins, but they are not really widgets or graphics at all.
 But that probably does not matter that much.  If a graphic can be added to X then X.pen is meaningfull

 PROBLEMATIC. Since 'brush' is a kind of shortcut method.
 We may use a similar design as 'struct' as shortcut for 'structure'.

 Well, that can be done but would be confusing.  And these are actually not graphics or widgets
 at all, so there creation method does not need to use the plugin system to begin with.
 They inherit Control so work like any other control, the instantiation method should not matter!
=end
      class Brush < Control
        include Graphical
        private
          # dynname is the assignment to be made on the parent!
          def initialize parent = nil, dynname = :qtbrush=
#             tag "new Brush(#{parent}, dynname = '#{dynname}'"
            super(parent, Qt::Brush.new)
            @dynname = dynname
          end

          def dynname arg
            @dynname = arg
          end

          # makes it a solid brush.
          def color *args, &block
#             tag "color(#{args.inspect})"
            case args[0]
            when Hash, nil
#               tag "a DynamicColor! on Brush#color"
              require_relative 'dynamiccolor'
              DynamicColor.new(self, :color, Qt::Color, args[0], &block)
            when Proc
              require_relative 'dynamiccolor'
              if args[0].arity == 1
                # same as { connector: block }
                DynamicColor.new(self, :color, Qt::Color, connector: args[0])
              else
                DynamicColor.new(self, :color, Qt::Color, args[0], &block)
              end
            else
#               tag "using make + make"
              @qtc = make_qtbrush(make_color(*args) # .tap{|c| tag "col=#{c.red},#{c.green},#{c.blue}"}
                )
            end
          end

        public
          def name aName = nil # not supported since Qt::Brush is not a Qt::Object at all. And we already index them too
          end

          def color= v
#             tag "color := #{v}"
            @qtc = make_qtbrush(v)
            # we  must reassign the entire brush or a graphicitem will not be updated at all.
            if parent
#               tag "#{parent}.#@dynname #@qtc"
              parent.send(@dynname, @qtc)
            end
          end

          # override
          def applyModel data
    #         tag "applyModel, data = #{data}"
            self.color = data
          end

      end # class Brush

      class Pen < Control
        include Graphical
        private
          def initialize parent = nil
            super(parent, Qt::Pen.new)
          end

          def color *args, &block
#             tag "pen#color, args[0] = #{args[0]}"
            case args[0]
            when Hash, nil
              require_relative 'dynamiccolor'
              DynamicColor.new(self, :color, Qt::Color, args[0], &block)
            when Proc
              require_relative 'dynamiccolor'
              if args[0].arity == 1
                # same as { connector: block }
                DynamicColor.new(self, :color, Qt::Color, connector: args[0])
              else
                DynamicColor.new(self, :color, Qt::Color, args[0], &block)
              end
            else
              @qtc = make_qtpen(make_color(*args))
            end
          end

          define_setter Float, :widthF

          alias :width :widthF
          alias :size :widthF
          alias :weight :widthF

#           remove_method(:widthF=)
          def widthF= v
            if parent
              @qtc = parent.pen
              @qtc.widthF = v
              parent.qtpen = @qtc
            end
          end

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

          CapMap = { :square => Qt::SquareCap, :project => Qt::SquareCap, :squarecap => Qt::SquareCap,
                    :flat => Qt::FlatCap, :flatcap => Qt::FlatCap,
                    :round => Qt::RoundCap, :roundcap => Qt::RoundCap }

          def capStyle value
            @qtc.capStyle = if Symbol === value then CapMap[value] || Qt::FlatCap else value end
#             tag "capStyle := #{@qtc.capStyle}, value = #{value}"
          end

          alias :cap :capStyle

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

        public # Pen methods
          def name aName = nil
          end

          # override
          def applyModel data
    #         tag "applyModel, data = #{data}"
            self.color = data
          end

          def color= v
            @qtc = make_qtpen(v)
            # we  must reassign the entire brush or a graphicitem will not be updated at all.
            parent.qtpen = @qtc if parent
          end

      end # class Pen

      class Font < Control
        private
          def initialize parent = nil
#             tag "loading font_model"
#             require_relative 'models/font_model'
#             tag "creating FontModel"
#             fm = FontModel.new(self)
            fm = Qt::Font.new('sans')
#             tag "parent = #{parent.inspect}"
#             tag "fm = #{fm}, calling super"
            super(parent, fm)
            @ptsize = -1 # systemdep. default
            @name = nil
          end

          def name aName
            @qtc.family = aName
            parent.qtfont = @qtc if parent
          end

          alias :family  :name

          def ptsize val
            @qtc.pointSize = val
            parent.qtfont = @qtc if parent
          end

          StyleMap = { italic: Qt::Font::StyleItalic, oblique: Qt::Font::StyleOblique, normal: Qt::Font::StyleNormal }

          def style val
            case val
            when Symbol then @qtc.style = StyleMap[val] || Qt::StyleNormal
            else @qtc.style = val
            end
          end
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
      end # class Gradient

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

    public # methods of Graphical

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
        # gray US spelling, grey EN spelling.
        gray: Qt::gray, darkGray: Qt::darkGray, lightGray: Qt::lightGray,
        grey: Qt::gray, darkGrey: Qt::darkGray, lightGrey: Qt::lightGray,
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
      #   - Qt::Color (as is), or Qt::Color plus alpha
      #   - Qt::Brush, using its color
      #   - a String like #rgb or #rrggbb or #rrrrggggbbbb or #rgba, (and similar) or a color name
      #   - Qt::Color enum member like Qt::white
      #   - int for red, and then arg2 = green, arg3 is blue, and arg4 is default 255 (alpha aka opaqueness)
      #         all values must be between 0 and 255
      #   - int for gray + optional alpha (aka opaqueness) value.
      #   - Array [r, g, b] or [r,g,b,a] or [grey, a] or [Qt::Color, a]
      #   - float. similar, but all values must be between 0.0 (darkest) and 1.0(lightest)
      def make_color colorsym, g = nil, b = nil, a = nil
#         tag "make_color(#{colorsym}, #{g}, #{b}, a:#{a})"
        case colorsym
    #     when Qt::Color, Qt::ConicalGradient, Qt::LinearGradient, Qt::RadialGradient then colorsym
        when Qt::Color
          return colorsym unless g
#           tag "Color + alpha combo!, colorsym = #{colorsym.inspect}"
          if Integer === g
            colorsym.alpha = g
          else
            colorsym.alphaF = g
          end
#           tag "with alpha #{g} -> #{colorsym.inspect}"
          colorsym
        when Qt::Brush then colorsym.color
        when String
          if colorsym[0] == '#'
            case colorsym.length
            when 5
              r = Qt::Color.new(colorsym[0...-1])
              alpha = colorsym[-1, 1].hex * 17
              r.alpha = alpha
            when 9
              # #rrggbbaa
              r = Qt::Color.new(colorsym[0...-2])
              alpha = colorsym[-2, 2].hex
              r.alpha = alpha
            when 13
              # #rrrgggbbbaaa
              r = Qt::Color.new(colorsym[0...-3])
              alpha = colorsym[-3, 3].hex / 4096.0
              r.alphaF = alpha
            when 17
              # #rrrrggggbbbbaaaa
              r = Qt::Color.new(colorsym[0...-4])
              alpha = colorsym[-4, 4].hex / 65536.0
              r.alphaF = alpha
            else
              r = Qt::Color.new(colorsym)
            end
            r
          else
            Qt::Color.new(colorsym)
          end
        when Qt::Enum then Qt::Color.new(colorsym)
        when Array
          if Qt::Color === colorsym[0]
#             tag "Color + alpha combo!"
            c = colorsym[0]
            alpha = colorsym[1]
            if Integer === alpha
              c.alpha = alpha
            else
              c.alphaF = alpha
            end
            c
          else
            Qt::Color.new(*colorsym)
          end
        when Integer
          if b
#             tag "3 or 4 integers"
            Qt::Color.new(colorsym, g, b, a || 255)
          else
#             tag "2 integers"
            Qt::Color.new(colorsym, colorsym, colorsym, g || 255)
          end
        when Float
          if b
            Qt::Color.new((colorsym * 255.0).floor, (g * 255.0).floor, (b * 255.0).floor,
                          ((a || 1.0) * 255.0).floor)
          else
            Qt::Color.new((colorsym * 255.0).floor, (colorsym * 255.0).floor, (colorsym * 255.0).floor,
                          ((g || 1.0) * 255.0).floor)
          end
        when Symbol
          if col = @@color[colorsym]
            col
          else
            col = containing_form.registeredBrush(colorsym) or
              raise Error, ":#{colorsym} is not a valid colorsymbol or registered brush, use #{@@color.keys.inspect}"
#             tag "color=#{col.color}, rgb=#{col.color.red},#{col.color.green},#{col.color.blue}"
            col.color
          end
        else raise Error, "invalid color #{colorsym}, #{g}, #{b}, #{a}"
        end
      end

#             alias :color :make_color                  CONFUSING!!

      # according to Hue, Saturation and Brightness.
      # ranges are: 0..360, 0..255, 0..255.
      # OR: 0.0 to 1.0 for all
      def hsb h, s = nil, b = nil, alpha = nil
#         tag "hsb(#{h}, #{s}, #{b}, #{alpha})"
        col = Qt::Color.new
        case h
        when Float then col.setHsvF(h, s || 1.0, b || 1.0, alpha || 1.0)
        when Integer then col.setHsv(h, s || 255, b || 255, alpha || 255)
        else raise Error, "invalid hsb #{h}, #{s}, #{b}"
        end
#         tag "rgb=#{col.red}, #{col.green}, #{col.blue}, #{col.alpha}"
        col # errr....
      end

      # 'value' == 'brightness'
      alias :hsv :hsb

      generateColorConverter :color2brush, Qt::Brush, @@solidbrush # DEPRECATED

      # convert anything into a Qt::Pen
      # Examples: make_qtpen 12, 3,
      #           make_qtpen :blue
      #           make_qtpen blue
      # The symbol param is the only one that caches the result.
      def make_qtpen_with_parent parent, *args, &block
#         tag "make_qtpen(args = #{args.inspect})"
        args = args[0] if args.length <= 1
        args = args.qtc if args.respond_to?(:qtc)
#         tag "make_qtpen args.class = #{args.class}, #{args.inspect}" # , caller=#{caller.join("\n")}"
        case args
        when Qt::Pen then args
        when false, :none, :nopen, :no_pen then @@pen[:none] ||= Qt::Pen.new(Qt::NoPen)
        when nil
          if block
            Pen.new(parent).setup(nil, &block).qtc
          else
            @@pen[:none] ||= Qt::Pen.new(Qt::NoPen)
          end
        when Symbol
          col = @@color[args] or raise Error, ":#{args} is not a valid colorsymbol, use #{@@color.keys.inspect}"
          @@pen[args] ||= Qt::Pen.new(col)
        when Hash then Pen.new(parent).setup(args, &block).qtc
        when Array then Qt::Pen.new(make_color(*args))
        when Qt::Color
#           tag "Using color #{args.red}, #{args.green}, #{args.blue}, alpha=#{args.alpha}"
          Qt::Pen.new(args)
        when Qt::Brush then Qt::Pen.new(args.color)
        else Qt::Pen.new(make_color(args))
        end
      end

      def make_qtpen *args, &block
        make_qtpen_with_parent nil, *args, &block
      end

      # convert anything into a Qt::Brush
      def make_qtbrush_with_parent parent, *args, &block
        args = args[0] if args.length <= 1
#         tag "make_qtbrush_with_parent #{args.inspect}, block=#{block}"
        args = args.qtc if args.respond_to?(:qtc)
        case args
        when Qt::Brush then args
        when false, :none, :nobrush, :no_brush then @@solidbrush[:none] ||= Qt::Brush.new(Qt::NoBrush)
        when nil
          if block
            Brush.new(parent).setup(&block).qtc
          else
            @@solidbrush[:none] ||= Qt::Brush.new(Qt::NoBrush)
          end
        when Symbol
#           tag "locating :#{args}"
          if col = @@color[args]
            @@solidbrush[args] ||= Qt::Brush.new(col) #) .tap{|b| tag "returning #{b}"}
          else
            col = containing_form.registeredBrush(args) or
              raise Error, ":#{args} is not a valid colorsymbol or registered brush, use #{@@color.keys.inspect}"
#             tag "color=#{col.color}, rgb=#{col.color.red},#{col.color.green},#{col.color.blue}"
            Qt::Brush.new(col.color) #.tap{|t| c=t.color; tag "RGB:#{c.red},#{c.green},#{c.blue},#{c.alpha}"}
          end
        when Qt::RadialGradient, Qt::LinearGradient, Qt::ConicalGradient then Qt::Brush.new(args)
        when Hash then Brush.new(parent).setup(args, &block).qtc
        when String
          if args[0, 7] == 'file://'
            pixmap = Qt::Pixmap.new(args[7..-1])
            raise ReformError, "Could not load pixmap '#{args[7..-1]}'" if pixmap.null?
#             tag "Creating brush from pixmap"
            Qt::Brush.new(pixmap)
          else
            Qt::Brush.new(make_color(args))
          end
        when Array then Qt::Brush.new(make_color(*args))
        when Qt::Color then Qt::Brush.new(args)
        else Qt::Brush.new(make_color(args))
        end
      end

      def make_qtfont_with_parent parent, *args, &block
        args = args[0] if args.length <= 1
        args = args.qtc if args.respond_to?(:qtc)
        case args
        when Qt::Font then args
        when String then Qt::Font.new(args)
        when nil, Hash then Font.new(parent).setup(args, &block).qtc
        when Symbol then containing_form.registeredFont(args) or raise Error, ":#{args} is not a registered font"
        else raise "Illegal font params #{args.inspect}"
        end #.tap {|f| tag "created font: #{f.toString}" }
      end

      def make_qtbrush *args, &block
        make_qtbrush_with_parent nil, *args, &block
      end

      def make_qtfont *args, &block
        make_qtfont_with_parent nil, *args, &block
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

      def radialgradient quickyhash = nil, &block
        RadialGradient.new.setup(quickyhash, &block)
      end

      def lineargradient quickyhash = nil, &block
    #     tag "lineargradient.new.setup(#{quickyhash}, #{block})"
        LinearGradient.new.setup(quickyhash, &block)
      end

      def defaultBrush
        @@defaultbrush ||= make_qtbrush(:white)
      end

      def defaultPen
        @@defaultpen ||= make_qtpen(:black)
      end

      def noPen
        @@nopen ||= make_qtpen(:none)
      end

      def noBrush
        @@nobrush ||= make_qtbrush(:none)
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
      def self.registerGroupMacro name, macro
        raise 'DAMN' unless GroupMacro === macro
        name = name.to_sym
        define_method name do |quicky = nil, &block|
#           tag "self=#{self}, executing GroupMacro #{macro}, quicky=#{quicky.inspect}"
          macro = containing_form.parametermacros[name] or return
#           tag "macro.hash=#{macro.quicky.inspect}"
#           require_relative 'graphics/empty'
          empty do
            rfRescue do
              instance_eval(&macro.block) if macro.block
              setupQuickyhash(macro.quicky) if macro.quicky
              instance_eval(&block) if block
              setupQuickyhash(quicky) if quicky
            end
          end
        end
      end

  end # Graphical

end # Reform