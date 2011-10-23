
# Copyright (c) 2010-2011 Eugene Brazwick

module Reform

  require 'reform/model'

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
      def initialize(*args)
	case args[0]
	when Qt::Font, String then super(*args)
	when Control 
	  super()
	  @model_parent = args[0]
        else super()
	end
      end

      @@fontDatabase = nil # Qt::FontDatabase.new

    public

      def parent= _
      end

      def self.db
        @@fontDatabase ||= Qt::FontDatabase.new
      end

      # list of styles for the current font, like 'normal', 'bold', 'italic'
      def styles # important to cache this
        return @styles if instance_variable_defined?(:@styles)
	require_relative 'structure'
  #       tag "#{self}::styles, family = #{family}"
  #       return @styles if instance_variable_defined?(:@styles)
        @styles = Structure.new(FontModel::db.styles(family))
      end

      def sizes
  #       tag "self=#{self}"
        return @sizes if instance_variable_defined?(:@sizes)
        fontDatabase = FontModel::db
        sizes = if fontDatabase.isSmoothlyScalable(family, fontDatabase.styleString(self))
  #         tag "using standardSizes"
          Qt::FontDatabase::standardSizes
  #           @sizeCombo.editable = true          FIXME, how can this be related ???
        else
  # 	tag "using smoothSizes, styleString='#{fontDatabase.styleString(self)}'"
          fontDatabase.smoothSizes(family, fontDatabase.styleString(self))
  #          @sizeCombo.editable = false  ""
        end
	require_relative 'structure'
	@sizes = Structure.new(sizes)
  #       tag "sizes=#{@sizes.inspect}"
  #       @sizes
      end #sizes

      #note that arg2 must be a string!
      def self.font family, style = 'Normal', ptsize = 10
        self.new(db.font(family, style, ptsize))
      end

      # IMPORTANT: Qt::Font does not 'behave' properly. It DOES document a 'style' method
      # but it does not exist!
      def model_getter?(name)
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

      def family= string
        model_pickup_tran do |tran|
	  org = family
	  super
#	  tag "addPropertyChange(:family, org=#{org})"
          tran.addPropertyChange(self, :family, org)
	end
      end

      # override to except a string
      def style= arg
        model_pickup_tran do |tran|
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
          tran.addPropertyChange(self, :style, org)
        end
      end

      def styleString= arg
        font = (db = FontModel::db).font(family, arg, pointSize)
        model_pickup_tran do |tran|
          org = db.styleString(self)
          # asssuming the family does not change:
          self.pointSize = font.pointSize
          self.weight = font.weight
          self.style = font.style
          self.fixedPitch = font.fixedPitch
          self.overline = font.overline
          self.stretch = font.stretch
          tran.addPropertyChange(self, :styleString, org)
  #         tag "style now set to #{font.style}, family = #{family}"
        end
      end

      def styleString value = nil
        return FontModel::db.styleString(self) if value.nil?
        self.styleString = value
      end

  #     fontDatabase.styleString(self)
      def pointSize= arg
        model_pickup_tran do |tran|
  #       tag "self=#{self}, family=#{family}, arg=#{arg.class} #{arg.inspect}"
          org = pointSize
          super
  #       tag "Calling dynamicPropertyChanged(pointSize), family is now #{family}"
          tran.addPropertyChange(self, :pointSize, org)
        end
      end

      def styleStrategy= arg
  #       tag "self=#{self}, styleStrategy:=#{arg}"
        model_pickup_tran do |tran|
          org = styleStrategy
          super
          tran.addPropertyChange(self, :styleStrategy, org)
        end
      end

      def fontMerging
	styleStrategy == Qt::Font::PreferDefault
      end

      def fontMerging= value
	self.styleStrategy = value ? Qt::Font::PreferDefault : Qt::Font::NoFontMerging
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
        super
      end

  end # class FontModel

  createInstantiator File.basename(__FILE__, '.rb'), nil, FontModel

end
