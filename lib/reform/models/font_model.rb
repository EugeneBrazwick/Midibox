
# Copyright (c) 2010 Eugene Brazwick

module Reform

  require_relative '../model'

=begin

Style problem.

The method   'style' and 'style=' work with Qt::Style which is an enum.
However the method 'styles' returning the possible styles for this family returns a stringlist
This will confuse the combobox.
Solution 1: alter 'style' to return a string instead (@@fontDatabase.styleString(self))
However that may break stuff.
Solution 2: make @styles a hash, and cache it.
WILL NOT WORK. Since 'Bold' is a style of 'gargi' but if applied it will result in style 0 == normal.
Add that's because 'style' only applies to 'italics' (a yes or no basically).
So 'styles()' is not related to style().

To fix this mess I make a new property, called stylestr. (Solution 3)
=end
  class FontModel < Qt::Font
    include Model

    private
#      def initialize(*args)
#        puts "new FontModel(#{args.inspect})"
#        super
#      end

      @@fontDatabase = nil # Qt::FontDatabase.new

    public

      def self.db
        @@fontDatabase ||= Qt::FontDatabase.new
      end

      def styles # important to cache this
  #       tag "#{self}::styles, family = #{family}"
  #       return @styles if instance_variable_defined?(:@styles)
        @styles ||= FontModel::db.styles(family)
  #       tag "stls = #{stls.inspect}"
  #       stls.each do |stylestr|
  # 	font = FontModel.new(self)
  # 	font.style = stylestr
  # 	tag "font[#{font.style.class} #{font.style}] := '#{stylestr}'"
  # 	@styles[font.style] = stylestr
  #       end
  #       tag "styles=#{@styles.inspect}"
  #       @styles
      end

      def sizes
  #       tag "self=#{self}"
        return @sizes if instance_variable_defined?(:@sizes)
        fontDatabase = FontModel::db
        @sizes = if fontDatabase.isSmoothlyScalable(family, fontDatabase.styleString(self))
  #         tag "using standardSizes"
          Qt::FontDatabase::standardSizes
  #           @sizeCombo.editable = true          FIXME, how can this be related ???
        else
  # 	tag "using smoothSizes, styleString='#{fontDatabase.styleString(self)}'"
          fontDatabase.smoothSizes(family, fontDatabase.styleString(self))
  #          @sizeCombo.editable = false  ""
        end
  #       tag "sizes=#{@sizes.inspect}"
  #       @sizes
      end #sizes

  #     def font
  #       tag "family=#{family}"
  # #       self
  #     end

      #note that arg2 must be a string!
      def self.font family, style = 'Normal', ptsize = 10
        self.new(db.font(family, style, ptsize))
      end

      # IMPORTANT: Qt::Font does not 'behave' properly. It DOES document a 'style' method
      # but it does not exist!
      def getter?(name)
        case name
        when :style, :pointSize then true
        else super
        end
      end

      def family value = nil
        return super() if value.nil?
  #       tag "Setting font family to '#{value}'"
        self.family = value
  #       tag "family is now #{family}"
        remove_instance_variable(:@sizes) if instance_variable_defined?(:@sizes)
        remove_instance_variable(:@styles) if instance_variable_defined?(:@styles)
      end

      # override to except a string
      def style= arg
        pickup_tran do |tran|
  #       if arg.respond_to? :to_str
  # 	tag "current family = #{family}"
  #         fontDatabase = @@fontDatabase
  # 	font = fontDatabase.font(family, arg, pointSize)
  # 	no_dynamics do
  # 	  # asssuming the family does not change:
  # 	  self.pointSize = font.pointSize
  # 	  super(font.style)
  # 	  tag "style now set to #{font.style}, family = #{family}"
  # 	end
  #       else
          org = style
          super
          tran.addPropertyChange(:style, org)
        end
      end

      def styleString= arg
        font = (db = FontModel::db).font(family, arg, pointSize)
        pickup_tran do |tran|
          org = db.styleString(self)
          # asssuming the family does not change:
          self.pointSize = font.pointSize
          self.weight = font.weight
          self.style = font.style
          self.fixedPitch = font.fixedPitch
          self.overline = font.overline
          self.stretch = font.stretch
          tran.addPropertyChange(:styleString, org)
  #         tag "style now set to #{font.style}, family = #{family}"
        end
      end

      def styleString value = nil
        return FontModel::db.styleString(self) if value.nil?
        self.styleString = value
      end

  #     fontDatabase.styleString(self)
      def pointSize= arg
        pickup_tran do |tran|
  #       tag "self=#{self}, family=#{family}, arg=#{arg.class} #{arg.inspect}"
          org = pointSize
          super
  #       tag "Calling dynamicPropertyChanged(pointSize), family is now #{family}"
          tran.addPropertyChange(:pointSize, org)
        end
      end

      def styleStrategy= arg
  #       tag "self=#{self}, styleStrategy:=#{arg}"
        pickup_tran do |tran|
          org = styleStrategy
          super
          tran.addPropertyChange(:styleStrategy, org)
        end
      end

      def pointSize arg = nil
        return super() if arg.nil?
        self.pointSize = arg
      end

      # override for debugging
      def to_s
        "Font<#{__id__} #{family} #{styleString} #{pointSize}pt>"
      end

      # it is weird but this must be like this or it breaks (sic)
      def toString
        super #.tap{|r|tag "toString -> #{r}"}
      end

      # toString also exists.
  end # class FontModel

  createInstantiator File.basename(__FILE__, '.rb'), nil, FontModel

end