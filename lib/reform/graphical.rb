module Reform

# this module contains generated and other 'brush' and 'pen' constructors.
# these will be used when rendering shapes on a graphicsitem, canvas or scene.
module Graphical
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
    tag "Mapping #{@@color[sym]}"
    @@color[sym] = Qt::Color.new(@@color[sym])
    tag "result = Qt::Color #{@@color[sym].red} #{@@color[sym].green} #{@@color[sym].blue}"
    define_method(sym) do
      @@color[sym]
    end
  end

  def color2brush colorsym
    case colorsym
    when Qt::Color then Qt::Brush.new(colorsym)
    when String, Integer then Qt::Brush.new(Qt::Color.new(colorsym))
    when Array then Qt::Brush.new(Qt::Color.new(*colorsym)) # must be 3 or 4 elements
    else
      @@solidbrush[colorsym] ||= Qt::Brush.new(@@color[colorsym])
    end
  end

  def color2pen colorsym
#     tag "red = Qt::Color #{red.red} #{red.green} #{red.blue}" -> 255, 0, 0
#     tag "color2pen #{colorsym}"
    case colorsym
    when Qt::Color then Qt::Pen.new(colorsym)
    when String, Integer then Qt::Pen.new(Qt::Color.new(colorsym))
    when Array then Qt::Pen.new(Qt::Color.new(*colorsym))
    else
#       tag "creating pen #{colorsym} with Qt color #{@@color[colorsym].inspect}"
      raise ReformError unless Qt::Color === @@color[colorsym]
      @@pen[colorsym] ||= Qt::Pen.new(@@color[colorsym])
    end
  end

  # horizontal gradient, with a linear pattern of brushes
  # if no brushes are given it is white to black (left to right)
  def gradient w, *brushes
    g = Qt::LinearGradient.new(0.0, 0.0, w, 0.0)
    brushes[0] = color2brush(:white) if brushes.empty?
    brushes[1] = color2brush(:black) if brushes.length < 2
    d = 1.0 / brushes.length
    j = 0.0
    brushes.each do |b|
      g.setColorAt j, b.color
      j += d
    end
    Qt::Brush.new g
  end

  def defaultBrush
    color2brush(:white)
  end

  def defaultPen
    color2pen(:black)
  end
end # Graphical

end # Reform