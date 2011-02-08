
require 'reform/app'

Scale = 2.0

=begin

  What if you can tie more than one model to a form or control.
  Or maybe Canvas specific?

  struct ......
  canvas {
    mouse  # activate mouse model here. As a result we receive events that
           # we pass as 'data' to our children as usual.
           # mousemodel is completely readonly. Transactions should not be possible.
    struct x: , y:..... , mouse: mouse {} #   similar with nested model ???
      # Actually I don't want models for controls, but canvas + mouse fit very well together.
    circle {
      center connector -> mouse { mouse.scenePos }   # this looks the best, and readonly is OK.
      center connector: [:mouse, :scenePos]  # combination-connector
      center connector: 'mouse.scenePos'  # parsed connector.
    }
  }

  If pmouseX/Y is to be used it is possible to use a timermodel, together with the mousemodel ?
  This is required for specific tricks where the 'previous' position is important.
  Maybe the mouse should track the last 24 positions, to make different 'lags' possible.

  Maybe 'mouse' can be a hack. It just merges as a datafield in the canvas behaving as if 'mouse'
  was altered, even if that field actually does not exist.
  Actually the message must be send through the scene, as that is the true owner of the items.
  But that probably will happen anyway.
=end

Reform::app {
  form {
    grid {
      columns 2
      define {
        canvas_params parameters {
          area 0, 0, 100, 100
          scale Scale
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
          circle2.center = event.scenePos.x, 16
          circle3.center = event.scenePos.x + 20, 50
          circle4.center = event.scenePos.x - 20, 84
        end
        circle name: :circle2, radius: 16.5
        circle name: :circle3, radius: 16.5
        circle name: :circle4, radius: 16.5
      } # canvas
      canvas {
        parameters :canvas_params
        whenMouseMoved do |event|
          circle5.center = event.scenePos.x, 16
          circle6.center = event.scenePos.x / 2, 50
          circle7.center = event.scenePos.x * 2, 84
        end
        circle name: :circle5, radius: 16.5
        circle name: :circle6, radius: 16.5
        circle name: :circle7, radius: 16.5
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
      } # canvas
    }
  }
}

# This works, but it has assignments.  BLECH!
