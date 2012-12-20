
#  Copyright (c) 2010-2011 Eugene Brazwick

module Reform

  require_relative 'combobox'

=begin
  strangely enough the font initially set is 'Sans'.
   but in the combobox this selects the  row 'DejaVu Sans'
   this causes severe problems
=end
  class FontComboBox < ComboBox
#     def connector
#       :font
#     end
    private
      #override
      def setCurrentIndex index, font
#	tag "setCurrentIndex(#{index}, #{font})"
	# could be problematic if font is nil ??
	@qtc.currentFont = font
      end

      # override. Use current since @data is bogus here
      def activated model, cid, idx
#        tag "YES, 'activated'!!!, idx = #{idx}, cid=#{cid}, model=#{model}, SELF:=#{current}"
	font = current
	model.transaction(self) do |tran|
	  model.family = font.family
	end 
      end

      def applyModel data
	#tag "applyModel(#{data.inspect})"
	@qtc.currentFont = FontModel.new(data)
      end

    public

#      def whenActivated &block
#	if block
#	  connect(@qtc, SIGNAL('activated(int)'), self) do |idx|
#  # 	  tag "ACTIVATED, family = current=#{current} #{current.family}"
#	    rfCallBlockBack(current, idx, &block)
#	  end
#	else
#	  @qtc.activated(@qtc.currentIndex)
#	end
#      end

      def currentFont
	@qtc.currentFont
      end

      def current
	require_relative '../models/font_model'
	return @qtc.currentFont if @qtc.currentFont.is_a?(Model)
	font = FontModel.new(@qtc.currentFont)
  #       tag "Copying font family = #{@qtc.currentFont.family}"
	unless font.family == @qtc.currentFont.family
	  raise "FAIL: font.fam=#{font.family}, qtc.cfont.fam=#{@qtc.currentFont.family}" 
	end
  #       tag "Wrapping currentFont #{@qtc.currentFont} in #{font}"
	# so the next time, we can return it immediately
	@qtc.currentFont = font
      end
  end # class FontComboBox

  createInstantiator File.basename(__FILE__, '.rb'), Qt::FontComboBox, FontComboBox

end # module Reform
