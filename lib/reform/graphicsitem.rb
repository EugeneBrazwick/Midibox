
require_relative 'control'
require_relative 'context'

module R::Qt

  class Rectangle
  end

  class Color < NoQtControl
    public
      alias hue= hsvHue=
      alias hue_get hsvHue_get
      alias saturation= hsvSaturation=
      alias saturation_get hsvSaturation_get

      attr_dynamic Fixnum, :alpha, :blue, :green, :red, 
			   :black, :cyan, :hslHue, :hslSaturation,
			   :hsvHue, :hsvSaturation, :lightness,
			   :magenta, :yellow, :value
      attr_dynamic Float, :alphaF, :blueF, :greenF, :redF, 
			  :blackF, :cyanF, :hslHueF, :hslSaturationF,
			  :hsvHueF, :hsvSaturationF, :lightnessF,
			  :magentaF, :yellowF, :valueF

      alias hue hsvHue
      alias saturation hsvSaturation

      class << self
	alias isValidColor validColor?
      end
  end # class Color

  class Brush < NoQtControl
    public
      attr_dynamic Color, :color, klass: DynamicColor, require: 'dynamic_color'
  end

  ## This diverts from the Qt hierarchy!!!
  # I don't suppose people want to use ruby to load 50000 items in a scene 
  class GraphicsItem < NoQtControl
      include Reform::GraphicContext

    private # methods of GraphicsItem

    public # methods of GraphicsItem

      # override
      def parent= parent
	parent.addGraphicsItem self
      end # parent=

      def addGraphicsItem item
	item.qtparent = self
      end # addGraphicsItem

      ## :call-seq:
      #	  brush	-> current brush
      #	  brush :blue
      #	  brush QBrush
      #	  brush { initblock }
      #	  brush inithash: .... 
      #
      #	PROBLEM:  getting a brush always makes a copy,
      #	and setting it too, actually.
      #
      #	Hence the VALUE returned by brush differs from the one last set.
      #	Now:
      #	    self.brush = Brush.new(self, *args, &block)
      # may call back en call self->setBrush().  For example if there is a block or a hash
      # containing 'connector'.
      #
      # This example shows that connector should NOT immediately fetch the required data.
      # However, my solution is now to revert the assigning of the brush to the brush constructor
      def brush *args, &block
	return brush_get unless args[0] || block
	#tag "calling Brush.new with parent #{self}"
	Brush.new self, *args, &block
      end # brush

      def pen *args, &block
	arg0 = args[0]
	return pen_get unless arg0 || block
	#tag "calling Brush.new with parent #{self}"
	Pen.new self, *args, &block
      end # pen

      attr_dynamic PointF, :pos

      alias :fill :brush
      alias :fillcolor :brush
      alias :stroke :pen

      # override
      def connect signal, proc
	TypeError.raise 'GraphicsItems only support ruby signals' unless Symbol === signal
	super
      end

      # override
      def emit signal, *args
	TypeError.raise 'GraphicsItems only support ruby signals' unless Symbol === signal
	super
      end
  end # class GraphicsItem

  class Brush < NoQtControl
    public # methods of Bruhs
      # override
      def parent= parent
	old_parent = @parent and old_parent.brush = nil
	@parent = parent and parent.brush = self
      end

      # override
      def apply_model data
	apply_dynamic_setter :color, data
      end
  end # class GraphicsItem

  class AbstractGraphicsShapeItem < GraphicsItem
     
    public # methods of AbstractGraphicsShapeItem

      # override
      def enqueue_children queue = nil
	super
	if @brush
	  queue and queue.push @brush or yield @brush
	end
	if @pen
	  queue and queue.push @pen or yield @pen
	end
      end

      # THIS IS INCORRECT. Since 'nil' if brush= was never called
      # But items have a default brush...
      # And same for Pen and same for lineitem!
      def brush_get; @brush; end
      def pen_get; @pen; end
  end # class AbstractGraphicsShapeItem

  class SynthItem < GraphicsItem
    public # methods of SynthItem
      #override
      def synthesized?; true; end
  end # class SynthItem

  class Pen < NoQtControl
    public # methods of Pen
      attr_dynamic Color, :color, klass: DynamicColor, require: 'dynamic_color'
      attr_dynamic Float, :widthF
      attr_dynamic Symbol, :capStyle, :joinStyle

      alias width widthF 
      alias size widthF
      alias weight widthF 
      alias cap capStyle
      alias join joinStyle 

      @@capstyles = @@joinstyles = nil
  end

  Reform.createInstantiator __FILE__, GraphicsItem
end

