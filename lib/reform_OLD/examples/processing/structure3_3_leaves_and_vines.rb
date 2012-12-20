
=begin

There is another way of defining structures through classes.

Let's try using a more direct copy of the 'processing' example first.

=end

require 'reform/app'
require 'reform/widgets/canvas'

H = 100

module Reform
  class Canvas < Widget
      def leaf x, y, size, dir
        shape {
          pen :none
          translation x, y
          scale size
          bezier dir, -0.7,
                 dir, -0.7, 0.4 * dir, -1.0, 0.0, 0.0,
                 0.0, 0.0, dir, 0.4, dir, -0.7
        }
      end

      def vine x, numLeaves, leafSize
        line from: [x, 0], to: [x, H], pen: :white
        gap = H.to_f / numLeaves
        direction = 1
        for i in 0...numLeaves
          r = gap * rand
          leaf x, gap * i + r, leafSize, direction
          direction = -direction
        end
      end
  end
end

Reform::app {
  form {
    hbox {
      define {
        canvas_params parameters {
          background lightGray
          area [0, 0, H, H]
          scale 3
        }
      }
      canvas {
        parameters :canvas_params
        # dir can be -1 or 1
        leaf 26, 83, 60, 1
      }
      canvas {
        parameters :canvas_params
        vine 33, 9, 16
      }
    }
  }
}

=begin

This is NOT the way to do it.
On the other hand, a 'vine' is so simple that we don't want a class for it?
Or actually 2.
Let's see, I think size can be given a negative value and then direction can be left out.
If that's the case we can create a 'shapegroup' for leaf.
Not a very good solution, since there is needless overhead.
Next 'vine'. Even more a 'builder'.

It should be possible to create a builder in a single class.

Let's delay this, even though I think it would not be very difficult.
=end