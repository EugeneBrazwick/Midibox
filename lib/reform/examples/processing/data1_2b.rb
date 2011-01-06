
require 'reform/app'

# addendum: I was wrong. A brush (fill) is a control like any other, and therefor supports
# 'connector'. It's value will then be assigned automatically
# so this is a bit more compact solution.

=begin

note to self: pens can easily be shared. This means changes must propagate down the line
even further.
But if the brush is replaced (which is very likely) how do I know which children had
no explicit brush set to begin with?

This is a simple matter of checking 'Qt::GraphItem.pen='.
although it may have overrides.
Code:           oldpen = pen. pen = newpen. foreach child: child.pen = newpen if child.pen.equal?(oldpen).

But there are consequences.
  fill black
  circle ....
  fill red
  circle ....

both circles will now be red.

=end

Reform::app {
  form {
    struct color: 'red'
    vbox {
      combobox struct: Qt::Color::colorNames, connector: :color #, debug_track: true
      canvas {
        sizeHint 230
        area [0, 0, 100, 100]
        scale 2
        circle {
          position 50, 50
          radius 30
          brush connector: :color
          square geometry: [0, 0, 30]
            # note that this uses the parents coordinate system and not
            # the one from the canvas.
            # The crux is that color changes should change both of them.
        }
      } # canvas
    } # vbox
  } # form
}

