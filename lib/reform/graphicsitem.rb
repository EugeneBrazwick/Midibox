
# Copyright (c) 2010 Eugene Brazwick

=begin

qtruby ANOMALY.
After Qt::GraphicsItem.setBrush(qbrush) the brush of the item is NOT qbrush at all.
So they cannot be used as pointers or references.

What happens if you say 'brush  x'?
a Qt::Brush is made.  It may also create Brush and even add it as a child, if a
Control is required.

But the methods 'brush' and 'pen' result in a qtbrush/qtpen only.

So GraphicsItem has to keep its own administration and a pen + brush are only set
if a pen or brush was actually declared. This way we know we can assign to all children
that have no reform pen/brush set.  To avoid confusion the qtpen/qtbrush handling methods
are now also called thus.

=end

module Reform

  class GraphicsItem < Control
    require_relative 'graphical'
    # each item can contain arbitrary children. using parentItem and childItems (Qt methods)
    include Graphical,  GraphicContext
    private

#       def initialize parent, qparent
#         super
#       end

      # position in the Scene (not the view). The translation
      def position tx = nil, ty = nil
        return @qtc.pos unless tx
        tx, ty = tx if Array === tx
#         tag "qtc.setPos := #{tx}, #{ty}, rect = #{@qtc.rect.inspect}"
        @qtc.setPos(tx, ty || tx)
#         tag "qtc.setPos := #{tx}, #{ty}, rect = #{@qtc.rect.inspect}"
      end

      alias :translate :position
      alias :pos :position

      def movable onoff = nil, &block
        case onoff
        when Hash, Proc then DynamicAttribute.new(self, :movable, TrueClass, onoff, &block)
        else @qtc.setFlag Qt::GraphicsItem::ItemIsMovable, onoff
        end
      end

      define_simple_setter :zValue

      define_setter Boolean, :visible

      # NOTE: this is 'fat'. Not every GraphicsItem has a geometry.
      def geometry x = nil, y = nil, w = nil, h = nil, &block
        return @qtc.geometry unless x || w || block
        case x
        when Array then self.geometry = *x
        when nil then DynamicAttribute.new(self, :geometryF, Qt::RectF).setup(nil, &block)
        when Hash, Proc then DynamicAttribute.new(self, :geometryF, Qt::RectF).setup(x, &block)
        else self.geometry = x, y, w, h
        end
      end

      # currently 'strength' is not supported. Actually tint should become a controller, of course
      def tint *args
#         tag "qtc = #@qtc"
        ef = Qt::GraphicsColorizeEffect.new(self) # @qtc)  not an object!!
        color = ef.color = make_color(*args)
        @qtc.setGraphicsEffect(ef)
        @qtc.opacity = color.alphaF if color.alphaF < 1.0
      end

    public # GraphicsItem methods

      attr :explicit_pen, :explicit_brush

      def movable= onoff
        @qtc.setFlag Qt::GraphicsItem::ItemIsMovable, onoff
      end

      # override, graphic items may be nested
      def addGraphicsItem control, quickyhash = nil, &block
        qc = if control.respond_to?(:qtc) then control.qtc else control end
        qc.parentItem = @qtc
        control.qtpen, control.qtbrush = pen, brush
#         tag "addGraphicsItem(#{control}), taking font = #{font} from parent"
        control.qtfont = font
        control.setup quickyhash, &block
        added control
      end

=begin
       IMPORTANT: pen or brushes can no longer be dynamic.
       This should be done with the 'color' attribute instead. As in:
       fill { color connector: :aha }
       This causes other complications... since we should really renew the brush or the pen of the
       item, and not manipulate the color internally...

       REASON: pen { size: 6 }  and pen { size 6  }
       is interpreted as a dynamic attribute. They are neither. Any item containing of components
       cannot be dynamic as this causes terrible ambiguities.
=end
      def fill *args, &block
#         tag "#{self}::fill(#{args.inspect}), block=#{block}"
        return @qtc.brush unless args[0] || block
#         tag "args[0].class = #{args[0].class}"
        @explicit_brush = self.qtbrush = case args[0]
          when Symbol then containing_form.registeredBrush(args[0]) || make_qtbrush_with_parent(self, *args)
  #         when Hash, Proc, nil then DynamicAttribute.new(self, :brush, Qt::Brush, args[0], &block).value
          when Qt::Brush then args[0]
          when nil #DynamicAttribute.new(self, :brush, Qt::Brush, nil, &block).value
            raise 'no block???' unless block
#             tag "do a quicky setup of Brush instance and use qtc"
            Brush.new(self).setup(&block).qtc # .tap{|t| tag "brush.qtc=#{t}"}
          else make_qtbrush_with_parent(self, *args)
          end
#         tag "assign brush #{@explicit_brush}, rgb=#{@explicit_brush.color.blue}, #{@explicit_brush.color.green}, #{@explicit_brush.color.blue}, alpha=#{@explicit_brush.color.alpha}"
      end

      def stroke *args, &block
#         tag "stroke #{args.inspect}"
        return @qtc.pen unless args[0] || block
        @explicit_pen = self.qtpen = case args[0]
          when Symbol then containing_form.registeredPen(args[0]) || make_qtpen_with_parent(self, *args)
  #         when Hash, Proc
  # #           tag "#{self}::stroke + Hash/Proc -> DynamicAttribute"
  #           DynamicAttribute.new(self, :pen, Qt::Pen, pen, &block).value
          when Qt::Pen then args[0]
          when nil then Pen.new(self).setup(&block).qtc
          else
    #       tag "stroke #{pen.inspect}"
            make_qtpen_with_parent(self, *args)
          end
#         tag "qtc.pen=#{@qtc.pen.inspect}, color=#{@qtc.pen.color.inspect}"
      end

      def font *args, &block
        return @qtc.font unless args[0] || block
        @explicit_font = self.qtfont = case args[0]
          when Symbol then containing_form.registeredFont(args[0]) || make_qtfont_with_parent(self, *args)
          when Qt::Font then args[0]
          when nil then Font.new(self).setup(&block).qtc
          else
            make_qtfont_with_parent(self, *args)
          end
      end

      # alias :background :fill                 DEPRECATED, confused with Canvas#background. Totally different idea.

      alias :brush :fill
      alias :fillcolor :fill
      alias :pen :stroke

      # Important, angles less than 1.0 degree are taken to be a factor of the
      # circles length (1.0 == 360 degr = 2*pi rad)
      def rotation degrees_cw, around_xy = nil
        degrees_cw *= 360.0 unless Integer === degrees_cw || degrees_cw.abs > 1.00000001
        if around_xy
          @qtc.setTransformOriginPoint(*around_xy)
        else
          @qtc.setTransformOriginPoint(0.0, 0.0)
        end
        @qtc.rotation = degrees_cw
      end

=begin EVIL
      # this uses Eugene circle units where 1.0 == 360 degrees.
      # except when degrees_ccw is an int or larger than 1
      def rotate degrees_ccw, around_xy = nil
        degrees *= 360.0 unless Integer === degrees || degrees.abs > 1.00000001
        if around_xy
          @qtc.setTransformOriginPoint(*around_xy)
        else
          @qtc.setTransformOriginPoint(0.0, 0.0)
        end
        @qtc.rotation += degrees
      end
=end

      def scale sx, sy = nil
        sx, sy = sx if Array === sx
        raise "scaling in two dimensions is not currently supported" if sy
#         tag "#{@qtc}.scale := #{sx}"
        @qtc.scale = sx
      end

#       def graphic?
#         true
#       end

#       def self.contextsToUse
#         GraphicContext
#       end

      def addTo parent, hash, &block
#         tag "#{parent}.addGraphicsItem(#{self})"
        parent.addGraphicsItem self, hash, &block
      end

      def qtbrush= newbrush
#         tag "#{self}#brush := #{newbrush}"
        newbrush = make_qtbrush(newbrush) unless Qt::Brush === newbrush
        @qtc.brush = newbrush
#         tag "#{self}.qtc.brush := #{@qtc.brush}, while brush = #{newbrush}"
        children.each do |child|
          child.qtbrush = newbrush if GraphicsItem === child && !child.explicit_brush
        end
#         tag "#{self}.qtc.brush := #{@qtc.brush}"
      end

      def qtpen= newpen
        newpen = make_qtpen(newpen) unless Qt::Pen === newpen
        @qtc.pen = newpen
        children.each do |child|
          child.qtpen = newpen if GraphicsItem === child && !child.explicit_pen
        end
      end

      def qtfont= newfont
        newfont = make_qtfont(newfont) unless Qt::Font === newfont
#         tag "#{self}#qtfont := #{newfont}, setting #@qtc.font"
        @qtc.font = newfont if @qtc.respond_to?(:font=)
        children.each do |child|
#           tag "assigning qtfont to child #{child}"
          child.qtfont = newfont if GraphicsItem === child && !child.explicit_font
        end
      end

      def geometry=(*value)  # this is quick 'n dirty.  FIXME
        STDERR.print "BAD call to GraphicsItem::geometry, causing inconsistent translation\n"
        # ALL gi's have a 'pos' but it is basicly the translation and not the upperleft corner of a
        # rectangle, or the center of a ellipse.
        # Current exception is Reform::Point which abuses pos as well. Yet another FIXME.
        value = value[0] if Array === value[0]
#         tag "qtc.pos := #{value[0]},#{value[1]}"
        @qtc.pos = Qt::Point.new(value[0], value[1])
        self.size  = Qt::Size.new(value[2],  value[3] || value[2])
      end

      # catches Qt's 'itemChange' event. Value is the value of the Qt::Variant, not the variant
      # Well, due to SEGV's that changed to 'sometimes'.
      # The default does nothing, and needs not return anything. The return value is currently
      # completely ignored...
      # See however the Qt doc, as there are special cases for specific values.
      def itemChange change, value
#         tag "itemChange #{change}, #{value.inspect}"
      end

=begin          TOO SOON, addTo may cause reparenting...
      def self.new_qt_implementor(qt_implementor_class, parent, qparent)
        tag "#{self}.new_qt_implementor, parent = #{parent}, parent.brush = #{parent.brush}"
        tmp = super
        tmp.pen, tmp.brush = parent.pen, parent.brush
        tmp
      end
=end

  end # class GraphicsItem

  # currently only used to get the itemChange callback working
  module QGraphicsItemHackContext
    private
      def drawSelectedRectArea painter, br
        murect = painter.transform.mapRect(Qt::RectF.new(0, 0, 1, 1))
        return unless [murect.width, murect.height].max > 0.0001
        mbrect = painter.transform.mapRect(br)
        return unless [mbrect.width, mbrect.height].min >= 1.0
        itemPenWidth = pen.widthF
        pad = itemPenWidth / 2.0
        penWidth = 0.0
        fgcolor = option.palette.windowText.color
        bgcolor = Qt::Color.new(fgcolor.red > 127 ? 0 : 255, fgcolor.green > 127 ? 0 : 255,
                                fgcolor.blue > 127 ? 0 : 255)
        painter.pen = Qt::Pen.new(bgcolor, penWidth, Qt::SolidLine)
        bradj = br.adjusted(pad, pad, -pad, -pad)
        painter.drawRect(bradj)
        painter.pen = Qt::Pen.new(option.palette.windowText, 0, Qt::DashLine)
        painter.drawRect(bradj)
      end

    public
      # override
      def itemChange change, value
  #       instance_variable_defined?(:@_reform_hack) and
        # CALLING value on BOGO variants causes SEGV's....
  #       tag "itemChange #{change}, #{value.inspect}, null? #{value.null?}, valid? #{value.valid?}"
        if @_reform_hack #  null if called from the constructor
          case change
          when Qt::GraphicsItem::ItemPositionChange, Qt::GraphicsItem::ItemPositionHasChanged,
              Qt::GraphicsItem::ItemScenePositionHasChanged
            @_reform_hack.itemChange(change, value.value)
          else
            @_reform_hack.itemChange(change, value)  # value.value crashes for some cases...
          end
        end
        super
      end

# INSANE...
#     def pen= pen; end
#     def brush= brush; end
#     def font= font; end
  end

end # Reform