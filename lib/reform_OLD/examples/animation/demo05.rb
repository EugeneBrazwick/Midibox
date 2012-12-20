
# Copyright (c) 2010 Eugene Brazwick

=begin
  This example shows a basic statemachine with animations in action.

  Same as demo04, but now in order

=end
require 'reform/app'

Reform::app {
  statemachine {
    states :s1, :s2, :s3
  }
=begin
 Kind of a hack?  Solved the dependencies by taking the scene out.
 Well, it works....
=end
  scene {
    name :myScene
    rect {
      brush {
#         tag "Creating animation :anim"
        animation {
          name :anim
          states s1: :blue, s2: :red, s3: :yellow
          duration 1000.ms
        }
      }
    }
  }
  button {
    text tr('Click Me')
# 1) it would seem the 'animation' tag here is superfluous. I already tied an animation to those
# states above.  A: there is only one know, but there might be two as well.
# 2) what if there are two rects with different color transitions.
# Then we need a parallelanimation parent for both.
# 3) What if there are two possible transition from some state to two different states?
# 4) What if there are two independent animations that use these states?
    whenClicked transitions [{from: :s1, to: :s2, animation: :anim},
                             {from: :s2, to: :s3, animation: :anim},
                             {from: :s3, to: :s1, animation: :anim}]
  }
  canvas {
    sizeHint 200
    scene :myScene
  }
}