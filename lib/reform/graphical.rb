module Reform

# this module contains generated and other 'brush' and 'pen' constructors.
# these will be used when rendering shapes on a graphicsitem, canvas or scene.
module Graphical
  private
  def self.generateColorConverter name, klass, cache
    define_method name do |colorsym, *more|
  #     tag "red = Qt::Color #{red.red} #{red.green} #{red.blue}" -> 255, 0, 0
#       tag "color2pen #{colorsym.inspect}"
      if Symbol == colorsym
        cache[colorsym] ||= klass.new(@@color[colorsym])
      else
        klass.new(color(colorsym, *more))
      end
    end
  end # generateColorConverter

public

  # index: colorsymbol, value: Qt::Brush
  @@solidbrush = {}
  @@pen = {}

  # these are of class Qt::Enum
  @@color = { white: Qt::white, black: Qt::black,
    yellow: Qt::yellow, red: Qt::red, blue: Qt::blue,
    green: Qt::green, darkRed: Qt::darkRed, darkGreen: Qt::darkGreen,
    darkBlue: Qt::darkBlue, cyan: Qt::cyan, darkCyan: Qt::darkCyan, teal: Qt::darkCyan,
    magenta: Qt::magenta, darkMagenta: Qt::darkMagenta,
    darkYellow: Qt::darkYellow, brown: Qt::darkYellow,
    gray: Qt::gray, darkGray: Qt::darkGray, lightGray: Qt::lightGray,
    transparent: Qt::transparent
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

=begin duplicate ???
  def color2brush colorsym
    case colorsym
    when Qt::Color then Qt::Brush.new(colorsym)
    when String, Integer then Qt::Brush.new(Qt::Color.new(colorsym))
    when Array then Qt::Brush.new(Qt::Color.new(*colorsym)) # must be 3 or 4 elements
    else
      @@solidbrush[colorsym] ||= Qt::Brush.new(@@color[colorsym])
    end
  end
=end

  # returns a Qt::Color
  def color colorsym, g = nil, b = nil, a = nil
    case colorsym
    when Qt::Color then colorsym
    when Qt::Brush then colorsym.color
    when String, Qt::Enum then Qt::Color.new(colorsym)
    when Array then Qt::Color.new(*colorsym)
    else
      case b
      when Integer then Qt::Color.new(colorsym, g, b, a || 255)
      when Float then Qt::Color.new(colorsym, (g * 255.0).floor, (b * 255.0).floor,
                                    ((a || 1.0) * 255.0).floor)
      else @@color[colorsym]
      end
    end
  end

  # color2X are helpers that convert color-parameters into a pen, or a brush
  # Examples: color2pen 12, 3, 4                color2pen :blue
  # The symbol param is the only one that caches the result.
  generateColorConverter :color2pen, Qt::Pen, @@pen
  generateColorConverter :color2brush, Qt::Brush, @@solidbrush

  # horizontal gradient, with width 'w' logical units and
  # a linear pattern of brushes or colors
  # if no brushes are given it is white to black (left to right)
  # with a single color it is that color to black (left to right)
  def gradient w, *brushes
    g = Qt::LinearGradient.new(0.0, 0.0, w, 0.0)
    brushes[0] = color(:white) if brushes.empty?
    brushes[1] = color(:black) if brushes.length < 2
    d = 1.0 / brushes.length
    j = 0.0
    brushes.each do |b|
      g.setColorAt j, color(b)
      j += d
    end
    Qt::Brush.new g
  end

  def defaultBrush
    color2brush :white
  end

  def defaultPen
    color2pen :black
  end
end # Graphical

end # Reform