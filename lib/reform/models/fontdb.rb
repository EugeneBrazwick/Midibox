
# This class models the fontfamily database

# Copyright (c) 2010 Eugene Brazwick

require_relative 'font_model'

module Reform

  # this class functions an array of fonts. Suitable to select a font from.
  # each entry functions as sample.
  # With _ptsize_ and _style_ you can tweak the samples supplied
  class FontFamilies < AbstractModel

    private
      def initialize parent, qtc
        super
        db = Qt::FontDatabase.new
        @style = 'Normal'
        @ptsize = 10
        @families = db.families
        @cache = {}
      end

      def ptsize value = nil
        return @ptsize unless value
        @ptsize = value
        @cache = {}
      end

      def style string = nil
        return @style unless string
        @style = string
        @cache = {}
      end

    public
      def length
        @families.length
      end

      def each
        @families.each do |fam|
          yield (@cache[fam] ||= FontModel.font(fam, @style, @ptsize))
        end
      end

      def row(numeric_idx)
#         tag "row(#{numeric_idx}): FontModel.new(#{@families[numeric_idx]}, #@style, #@ptsize)"
        @cache[@families[numeric_idx]] ||= FontModel.font(@families[numeric_idx], @style, @ptsize)
      end

  end

  createInstantiator File.basename(__FILE__, '.rb'), nil, FontFamilies

end