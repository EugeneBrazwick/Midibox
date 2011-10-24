
# Theme singleton -> $theme

module Midibox

  class BaseTheme
    ImagesDir = File.dirname(__FILE__) + '/../../gui/images/'

    Palette = { red: [251, 44, 44, 180],
                orange: [255, 174, 78, 150],
                yellow: [241, 252, 126, 120],
                green: [26, 231, 34, 140],
                blue: [132 , 247, 248, 150],
                purple: [103, 108, 239, 120],
                pink: [249, 109, 238, 120],
                gray: [206, 206, 206, 180],
                black: [:black], # solid
                white: [:white] # solid
              }.inject({}) do |hash, el| 
	      k, v = el 
	      hash[k] = Reform::Graphical::make_qtbrush(*v) 
	      hash 
	    end

      # initial width
      UnitH = 32
      InitW = UnitH * 5
      GlyphSize = Qt::Size.new((UnitH * 3) / 4, (UnitH * 3) / 4)
      TitleH = UnitH + 4
      RadiusEdge = 32
      BlurRadius = 9.0 # of the dropshadow
      BlurColor = Reform::Graphical::make_color(160, 160, 50, 88)

      Palette.keys.each do |sym|
        define_method sym do
          Palette[sym]
        end
      end

      def initW; InitW end
      def minWidth; UnitH * 4; end
      def unitH; UnitH end
      def titleH; TitleH end
      def radiusEdge; RadiusEdge end # take this absolute or it is damn UGLY
      def blurRadius; BlurRadius; end
      def blurColor; BlurColor; end
      def glyphSize; GlyphSize; end

      def sizerGlyphPath; ImagesDir + 'sizer3.svg'; end
      # it appears qt doesn't really interpret svg correctly when loading a pixmap.
      # no filters or blur etc. applied.
      def collapseGlyphPath; ImagesDir + 'collapse3.svg'; end
      def expandGlyphPath; ImagesDir + 'expand3.svg'; end
      def showcontrolsGlyphPath; ImagesDir + 'showcontrols3.svg'; end
  end

  $theme = BaseTheme.new
end
