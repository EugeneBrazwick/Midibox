
# Copyright (c) 2010-2011 Eugene Brazwick

module Reform

  require 'reform/graphicsitem'

  class Rectangle < GraphicsItem
  private

    # qtc is QGraphicsRectItem
    def initialize parent, qtc
      super
#       tag "creating #{self} with parent #{parent}"
      size 100
    end

=begin
 Setting topLeft or bottomRight WILL change the size currently.
 A rectangle must now be given as topleft + size or topleft + bottomright or bottomright + topleft
 bottomright + size will NO longer work!!
 I simply follow the Qt::RectF standard here.
=end
    define_setter Qt::SizeF, :size
    define_setter Qt::PointF, :topLeft, :bottomRight, :topRight, :bottomLeft
    define_setter Float, :left, :right, :top, :bottom, :height, :width

    alias :topleft :topLeft
    alias :bottomright :bottomRight

=begin org
    def size w = nil, h = nil
      return @qtc.rect.size unless w
      w, h = w if Array === w
      # for some reason rect.x is anything except x!
      @qtc.setRect(@qtc.rect.x, @qtc.rect.y, w, h || w)
    end
=end

=begin org
    def topleft x, y = nil
      x, y = x if Array === x
#       tag "calling setRect(#{x}, #{y}, #{@qtc.rect.width}, #{@qtc.rect.height})"
      @qtc.setRect(x, y, @qtc.rect.width, @qtc.rect.height)
    end

    # should follow 'topleft'
    def bottomright x, y = nil
      x, y = x if Array === x
      r = @qtc.rect
      rx, ry = r.x, r.y
      @qtc.setRect(rx, ry, x - rx, y - ry)
    end
=end

  public

    def geometry=(x, y = nil, w = nil, h = nil)
#       tag "geo=(#{x.inspect}, #{y}, #{w}, #{h})"
      @qtc.rect = case x
      when Array
        x[3] ||= x[2]
#         tag "Qt::RectF.new(x = #{x.inspect})"
        Qt::RectF.new(*x)
      when Qt::RectF then x
      else Qt::RectF.new(x, y, w, h || w)
      end
    end

    alias :geometryF :geometry
    alias :geometryF= :geometry=

  end # Rectangle

  class QGraphicsRectItem < Qt::GraphicsRectItem
    include QGraphicsItemHackContext
    private
      def self.define_corner_assigners *names
        names.each do |name|
          assname = (name.to_s + '=').to_sym
          define_method assname do |x, y = nil|
            r = rect
            r.send(assname, Qt::PointF === x ? x : Qt::PointF.new(x, y || x))
            self.rect = r
          end
        end
      end

      def self.define_side_assigners *names
        names.each do |name|
          assname = (name.to_s + '=').to_sym
          define_method assname do |x|
            r = rect
            r.send(assname, x)
            self.rect = r
          end
        end
      end

    public

=begin added requirements for animations:
      define_setter Qt::SizeF, :size, :topLeft, :bottomRight, :topRight, :bottomLeft
      define_setter Float, :left, :right, :top, :bottom, :height, :width
=end
      def size= x, y = nil
        r = rect
#         tag "assigning #{x.inspect}, #{y.inspect} to rect #{r}"
        r.size = Qt::SizeF === x ? x : Qt::SizeF.new(x, y || x)
        self.rect = r # I expect 'update' is automatically called
      end

      define_corner_assigners :topLeft, :topRight, :bottomLeft, :bottomRight
      define_side_assigners :top, :bottom, :right, :left, :width, :height
  end;

  createInstantiator File.basename(__FILE__, '.rb'), QGraphicsRectItem, Rectangle

end # Reform