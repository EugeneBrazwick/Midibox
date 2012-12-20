
# PARAMS!!

require 'reform/app'
require 'reform/graphics/graphicspath'

module Reform

  class Arch < PathItem
    private
#       tag "define_setter curvature"
      define_setter Float, :curvature

=begin Why is this not called???

Because you must actually use the property 'curvature' to set it to
some value.
Without a value there will not even be a curve.
That could be fixed though.
=end
      def curvature= f
        @curvature = f
        redofromstart
      end

      def redofromstart
#         tag "curvature := #{f}"
        startPath
        y = 90.0
        bezier 15.0, y,
               15.0, y - @curvature, 30.0, 55.0, 50.0, 55.0,
               70.0, 55.0, 85.0, y - @curvature, 85.0, y
        endPath
      end
  end

  registerKlass GraphicsItem, :arch, QGraphicsPathItem, Arch
end # Reform

Reform::app {
  form {
    struct curvature: 15.0
    hbox {
      slider orientation: :vertical, range: [0.0, 100.0], connector: :curvature
      canvas {
        area 0, 0, 100, 100
        scale 3
        background gray
        fill :none
#        pen weight: { connector: -> data { (100.0 - data.curvature) / 6.0 } }
        pen weight: -> data { (100.0 - data.curvature) / 6.0 }
=begin alterative syntax:\

        pen {
          weight {
            connector { |data| (100.0 - data.curvature) / 6.0 }
          }
        }

# maybe shortcut this: we know the argcount of the block (I think), so if it 0
then it is a setup-proc. Otherwise we can assign it to @connector immediately.
The result would then be:

        pen {
          weight { |data| (100.0 - data.curvature) / 6.0 }
        }

Or:
        pen weight: -> data { (100.0 - data.curvature) / 6.0 }

It looks very nice not?


It is also how I wrote it first, and then it completely did not work.
=end


=begin OK
        shape {
          y, f = 90.0, 25.0
          bezier 15.0, y,
                 15.0,y - f,  30.0,55.0, 50.0,55.0,
                 70.0,55.0, 85.0,y - f, 85.0,y
        }
=end
        arch { # oh my god.... we must USE that parameter.
          curvature connector: :curvature
        }
      }
    }
  }
}