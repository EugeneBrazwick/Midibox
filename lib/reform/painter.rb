
module Reform

  class Painter < Qt::Painter
    attr_accessor :event

    def brush= value
#       tag "brush = #{value.inspect} value.class=#{value.class}, Qt::white=#{Qt::white}, Qt::Dense6Pattern=#{Qt::Dense6Pattern}"
      case value
      when Qt::Color then value = Qt::Brush.new(value)
        # supported is a color or else a brushstyle
      when Qt::Enum then if value.type == 'Qt::GlobalColor' then value = Qt::Brush.new(value) end
      when String then value = Qt::Brush.new(Qt::Color.new(value))
      end
      method_missing(:brush=, value)
    end

    def pen= value
      case value
      when Qt::Enum then if value.type == 'Qt::GlobalColor' then value = Qt::Color.new(value) end
      end
#       tag "pen := #{value.inspect}"
      method_missing(:pen=, value)
    end
  end
end