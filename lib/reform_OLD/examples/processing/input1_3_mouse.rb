
# OLD and NEW toegether

# The NEW ones are slightly sluggish.
# This is hard to believe since the amount of processing should be fairly limited...
# may require some profiling to figure out what precisely is the problem

require 'reform/app'

Reform::app {
  form {
    grid {
      columns 2
      define {
        canvas_params parameters {
          area 0, 0, 100, 100
          scale 2
          background 'hotpink'
          mouseTracking true
          pen :none
        }
      }
      canvas {
        parameters :canvas_params
        whenMouseMoved do |event|
          # scenePos is not Qt, but a reform extension.
          circle1.center = event.scenePos
        end
        circle name: :circle1, radius: 16.5 #, pen: :none
      } # canvas
      canvas {
        parameters :canvas_params
        whenMouseMoved do |event|
          pt = event.scenePos
          circle9.center = pt.x, 50
          circle9.radius = pt.y / 2
          circle8.center = 100 - pt.x, 50
          circle8.radius = 100 - pt.y
        end
        circle name: :circle9, center: [50, 50], fill: [255, 150]
        circle name: :circle8, center: [50, 50], fill: [0, 159]
      }
      canvas {
        parameters :canvas_params
        mouse
=begin
  'mouse' activates the mouse model.
  This propagates an item with property 'mouse' (alias 'mouseEvent')
  but also 'scenePos'.

  This way it can be figured out what was passed in case there are other models
  too. This solution is not the brightest.

  Hm, you should be able to set the path. How can I say I want to except only 'mouse'.
  Maybe with:

      connector: [:mouse, -> ev { ev.scenePos }]

=end
#         track_propagation  true
        circle {
          radius 16.5

          #center -> mouse { mouse.mouse.scenePos }  # can be shortcut to:
          center -> mouse { mouse.scenePos }
        } # circle
      } # canvas
      canvas {
        parameters :canvas_params
        mouse # !
#         track_propagation true
        circle {
          center -> mouse { [mouse.scenePos.x, 50] }
          radius -> mouse { mouse.scenePos.y / 2 }
          fill 255, 150
        }
        circle {
          center connector: -> mouse { [100 - mouse.mouse.scenePos.x, 50] }
          # the next one will work even if other models are involved (theoretically!)
          radius connector: [[:mouse, -> ev { 100 - ev.scenePos.y }]]
          fill 0, 159
        }
      } # canvas
    } # grid
  } # form
} # app