
module Reform

  class Painter < Qt::Painter
    require 'reform/graphical'
    include Graphical

    private

      # difference: you can now pass block and not worry about the 'end' anymore.
      # abviously you should pass a device as well in that case.
    def initialize device = nil
#       tag "new Qt::Painter(#{device}) ++ "
      if device
#         tag "IMPLICIT Qt::Painter::begin, block_given=#{block_given?}"
        super(device)
      else
        super()
      end
#       tag "new Qt::Painter, block_given = #{block_given?}"
      self.renderHint = Antialiasing
      if block_given?
        begin
#           tag "Passing on to block"
          yield self
        ensure
          if device
#             tag "CALLING Qt::Painter::end"
            self.end
          end
        end
      end
    end

    public

#     attr_accessor :event

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

    def fillRect *args
      case args.length
      when 2
        # always rect + brush
        args[1] = make_brush(args[1])
      when 5
        # always x, y, w, h + brush. Hence:
        args[4] = make_brush(args[4])
      end
      method_missing(:fillRect, *args)
    end
  end
end