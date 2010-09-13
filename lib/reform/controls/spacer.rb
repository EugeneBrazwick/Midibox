
#  Copyright (c) 2010 Eugene Brazwick

module Reform

  class Spacer < Widget
  private
    def initialize parent, qtc = nil
      super
      # only used by grids:
      @orientation = Qt::Horizontal | Qt::Vertical
      @spacing = nil
      @stretch = nil
    end

    def orientation o
      case o
      when :horizontal then o = Qt::Horizontal
      when :vertical then o = Qt::Vertical
      end
      @orientation = o
    end

    public
      # for grids, you can specify
    def spacing v = nil, w = nil
      return instance_variable_defined?(:@spacing) ? @spacing : nil unless v
      if w
        @spacing = v, w
      else
        @spacing = v
      end
    end

    alias :space :spacing
    # and we have 'stretch' from parent

#     attr :orientation AARG

    def hor_spacing
#       tag "hor_spacing, @spacing=#{@spacing.inspect}, or=#@orientation"
      if Array === @spacing then @spacing[0] elsif (@orientation & Qt::Horizontal) then @spacing else nil end
    end

    def ver_spacing
      if Array === @spacing then @spacing[1] elsif (@orientation & Qt::Vertical) then @spacing else nil end
    end

    def hor_stretch
      if Array === @stretch then @stretch[0] elsif (@orientation & Qt::Horizontal) then @stretch else nil end
    end

    def ver_stretch
      if Array === @stretch then @stretch[1] elsif (@orientation & Qt::Vertical) then @stretch else nil end
    end

  end

=begin
  class QSpacerItem < Qt::SpacerItem
    private
      def initialize parent = nil
        super( 20, 20)
      end

    public

    attr_accessor :orientation

    def expandingDirections
      o = orientation and return o
      super
    end
  end
=end

  createInstantiator File.basename(__FILE__, '.rb'), nil, Spacer
end # Reform