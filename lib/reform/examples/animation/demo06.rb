
# Copyright (c) 2010 Eugene Brazwick

=begin
  This example shows a basic statemachine with parallel animations in action.

  Same as demo05, but with two animations

=end
require 'reform/app'

Reform::app {
  statemachine {
    states :s1, :s2, :s3
  }
  parallelanimation name :anim
  scene {
    name :myScene
    rect {
      brush {
#         tag "Creating animation :anim"
        animation {
          appendto :anim
          states s1: :blue, s2: :red, s3: :yellow
          duration 1000.ms
        }
      }
    }
    rect {
      brush {
#         tag "Creating animation :anim"
        animation {
          appendto :anim
          states s1: :blue, s2: :yellow, s3: :red
          duration 1000.ms
        }
      }
    }
  }
  button {
    text tr('Click Me')
    whenClicked transitions [{from: :s1, to: :s2, animation: :anim},
                             {from: :s2, to: :s3, animation: :anim},
                             {from: :s3, to: :s1, animation: :anim}]
  }
  canvas {
    sizeHint 200
    scene :myScene
  }
}