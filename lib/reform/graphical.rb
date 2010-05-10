module Reform

# this module contains generated and other 'brush' and 'pen' constructors.
# these will be used when rendering shapes on a graphicsitem, canvas or scene.
module Graphical
public
  def self.define_color name, col
    define_method(name) do
      @@solidbrush[name] ||= Qt::Brush.new(col)
    end
  end

  # index: colorsymbol, value: Qt::Brush
  @@solidbrush = {}

  { white: Qt::white, black: Qt::black,
    yellow: Qt::yellow, red: Qt::red, blue: Qt::blue,
    green: Qt::green, darkRed: Qt::darkRed, darkGreen: Qt::darkGreen,
    darkBlue: Qt::darkBlue, cyan: Qt::cyan, darkCyan: Qt::darkCyan, teal: Qt::darkCyan,
    magenta: Qt::magenta, darkMagenta: Qt::darkMagenta,
    darkYellow: Qt::darkYellow, brown: Qt::darkYellow,
    gray: Qt::gray, darkGray: Qt::darkGray, lightGray: Qt::lightGray,
    transparent: Qt::transparent
  }.each do |nam, col|
    self.define_color nam, col
  end

  def gradient w, *brushes
    g = Qt::LinearGradient.new(0.0, 0.0, w, 0.0)
    brushes[0] = white if brushes.empty?
    brushes[1] = black if brushes.length < 2
    d = 1.0 / brushes.length
    j = 0.0
    brushes.each do |b|
      g.setColorAt j, b.color
      j += d
    end
    #  puts "#{File.basename(__FILE__)}:#{__LINE__}:g =#{g}"
    Qt::Brush.new g
  end

  def defaultBrush
    white
  end

  def defaultPen
    black
  end
end # Graphical

end # Reform