
=begin

Functions.

Problematic.

Why? Where to put them?

If you have a single canvas, then shapemakers could be 'deffed' inside it.
But you cannot use that maker inside another canvas.

Finally you can make a class. Even here. And then use it like any other graphic.
That's probably going to be example structure3_2_xs.rb
=end

require 'reform/app'

# Make it available to all canvas items anywhere:
module Reform
  require 'reform/widgets/canvas'
  class Canvas
   public
     def my_eye_function
        pen :none
        circle center: [50, 50], radius: 30, fill: white
        circle center: [60, 50], radius: 15, fill: black
        circle center: [66, 45], radius: 3, fill: red
      end
  end
end

Reform::app {
  form {
    grid {
      columns 3
      # TODO: parameters also fit perfectly in a 'define' section.
      define {
        canvas_params parameters {
          area 0, 0, 100, 100
          scale 2
          background 'hotpink'
        }
        # Thinking about it 'shapegroup' IS IDENTICAL TO 'parameters'!
        # However, it also extends the Graphical module with a method.
        eye shapegroup {
          pen :none
          circle center: [50, 50], radius: 30, fill: white
          circle center: [60, 50], radius: 15, fill: black
          circle center: [66, 45], radius: 3, fill: white
        }
      } # define
      canvas { #  I
        parameters :canvas_params
        # just literally copy the code inside
        pen :none
        circle center: [50, 50], radius: 30, fill: white
        circle center: [60, 50], radius: 15, fill: black
        circle center: [66, 45], radius: 3, fill: white
      }
      canvas { # II
        parameters :canvas_params
        eye # but is the almost the same as 'parameters :eye' (but you can pass additional params!)
      }
      canvas { # III
        parameters :canvas_params
        # this 'eye' works too, but only in this very canvas.
        def eye tx = 0, ty = 0
          pen :none
          # putting 'translation' here is WRONG.  that would apply it to the canvas.
          circle {
            center 50, 50
            radius 30
            fill white
            translation tx, ty
            # these circles are nested properly.
            circle center: [60, 50], radius: 15, fill: black
            circle center: [66, 45], radius: 3, fill: green
          }
        end
        eye 15, -6
        eye -30, 0
      }
      canvas { # IV
        parameters :canvas_params
        my_eye_function
      }
      canvas { # V
        parameters :canvas_params
        # using the shapegroup
        eye pos: [15, -6]
        eye pos: [-30, 0]
      }
      canvas { # VI
        parameters :canvas_params
        # with 'def' you can add setup-parameters like this:
        def eye x = 0, y = 0
          pen :none
          circle {
            translation x, y  # NOT center
            radius 30
            fill white
            circle center: [10, 0], radius: 15, fill: black
            circle center: [16, -5], radius: 3, fill: 'hotpink'
          }
        end
        eye 65, 44
        eye 20, 50
        eye 65, 74
        eye 20, 80
        eye 65, 104
        eye 20, 110
        # wouldn't    eye x: 65, y: 44 be better?   or    eye at: [65, 44]
        # too many eyes, it's getting pornographic!
      }
    }
  }
}
