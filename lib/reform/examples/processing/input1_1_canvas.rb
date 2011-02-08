=begin
Big problem:

  mouseevents are sent to specific widgets. We are now trying the tie a global
  event to it. But it is important that the position is relative to the current
  widget.
  This could even be problematic.
  If 'circle' was a real widget the mouse pos given would be totally useless.
  And even if not, the pos given should be the pos in the scene, ie whatever
  the window position is the area is 0,0,100,100 so the mousepos should be
  inside that area as well.

  Note that QGraphicsView already maps mouse events and forwards them to
  a specific QGraphichsItem!

  In example 1 a specific item tracks the mouse. But it will respond
  to mouse move events even outside itself. This makes it awkward.


app { form {
        mouse
        canvas {
          mouseTracking true # ?
          area 0, 0, 100, 100
          circle {
            center connector: :pos
}}}}

Conclusion: it will not work that way

=end

# How does the mouse work by default in a canvas?

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
        }
      }
      canvas {
        parameters :canvas_params
        whenMouseMoved do |event|
          STDERR.print "event.pos = #{event.pos.inspect}, posF = #{event.posF.inspect}, " +
                      "globalPos = #{event.globalPos.inspect}\n"
          STDERR.print "event = #{event.inspect}"
        end
=begin
    moves are not automatic. You must click+drag first.
    pos and posF are the same and relative to the widgets topleft.
    globalPos are absolute screencoordinates (so not even form).
    The area is not used
=end
        rect geo: [1,1,98,98], brush: :none
      }
      canvas {
        parameters :canvas_params
        mouseTracking true
        whenMouseMoved do |event|
          STDERR.print "event.pos = #{event.pos.inspect}, posF = #{event.posF.inspect}, " +
                      "globalPos = #{event.globalPos.inspect}\n"
          STDERR.print "event = #{event.inspect}"
        end
        rect geo: [1,1,98,98], brush: :none
      }
      canvas {
        parameters :canvas_params
        rect geo: [1,1,98,98], brush: :none
        circle {
#           whenMousePressed {}                 OK.
          mouseTracking true  # same effect, but more consistent
          whenMouseMoved do |event|
            STDERR.print "event.pos = #{event.pos.inspect}, scenePos=#{event.scenePos.inspect}, " +
                        "screenPos=#{event.screenPos.inspect}\n"
            STDERR.print "event.lastPos = #{event.lastPos.inspect}, scenePos=#{event.lastScenePos.inspect}, " +
                        "screenPos=#{event.lastScreenPos.inspect}\n"
          end
=begin
  screenPos is the same as globalPos
  scenePos and pos use 'area' but 'pos' uses the itemcoordinates
  the ones with the prefix 'last' return the previous position
=end
        }
      } # canvas
      canvas {  # Both
        parameters :canvas_params
        rect geo: [1,1,98,98], brush: :none
        mouseTracking true
        whenMouseMoved do |event|
          STDERR.print "event.pos = #{event.pos.inspect}, posF = #{event.posF.inspect}, " +
                      "globalPos = #{event.globalPos.inspect}\n"
          STDERR.print "event = #{event.inspect}"
        end
        circle {
          mouseTracking true  # same effect, but more consistent
          whenMouseMoved do |event|
            STDERR.print "event.pos = #{event.pos.inspect}, scenePos=#{event.scenePos.inspect}, " +
                        "screenPos=#{event.screenPos.inspect}\n"
            STDERR.print "event.lastPos = #{event.lastPos.inspect}, scenePos=#{event.lastScenePos.inspect}, " +
                        "screenPos=#{event.lastScreenPos.inspect}\n"
          end
        }
=begin
  when you press the button in the circle that item takes over all mouse move messages.
=end
      } # canvas
    } # grid
  }
}
