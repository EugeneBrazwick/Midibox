
# Copyright (c) 2010 Eugene Brazwick

=begin
  This example shows a basic statemachine with animations in action.

  Same as demo03, but now smooth animations between the 3 states.

=end
require 'reform/app'

Reform::app {
  statemachine {
#     name :myStatemachine
    states :s1, :s2, :s3
  }
  canvas {
    sizeHint 200
    rect {
#       sizw
      brush {
        tag "Creating animation :anim"
        animation {
          name :anim
          states s1: :blue, s2: :red, s3: :yellow
          duration 1000.ms
        }
      }
    }
  }
  button {
=begin
I discovered a design error,
We need :anim in the button, but it only becomes available
when canvas is instantiated.
Solutions: 1) put button last. UGLY. Also if a canvas is first we don't get the automatic 'formlayout' anymore.
           2) 'can' the brush in a 'defines' section. Can't do, 'defines' is not available
            outside a canvas (at this moment, but could move it to any frame, or even the application )
           3) using 'postSetup'. Will NOT work. The postSetup are called for each after the child is finished, not
           after ALL childs are finished.

4) Something that worked in 'phpforms' (a project started in 2000, similar to reform):
'name' a control and then use the name to refer to it. No control is added, but properties may change.

    button { name: :me ..... }
    ..
    canvas { ... }
    ..
    control(:me) { ...  whenClicked transitions [] }

In that case postSetup is called twice so it isn't really a nice solution.

5) defining a postPostSetup. When the parent has completed all children it calls postPostSetup on
them. This would allow for some 'picking up' but 'whenClicked()' must then set some state
in button that could be picked up.  It seems double work.  Maybe 'postSetup' must always be
delayed like that.

=end
    text tr('Click Me')
#     whenClicked transitions {
#       transition from: :s1, to: :s2, animation: :anim
#       transition from: :s2, to: :s3, animation: :anim
#       transition from: :s3, to: :s1, animation: :anim
#     }
    # OR:
    whenClicked transitions [{from: :s1, to: :s2, animation: :anim},
                             {from: :s2, to: :s3, animation: :anim},
                             {from: :s3, to: :s1, animation: :anim}]
  }
}