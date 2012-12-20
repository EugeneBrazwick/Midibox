
require 'reform/app'

Reform::app {
  form {
    struct x: 20, units: 7, angle100: -12
    hbox {
      vbox {
        label text: 'X'
        slider orientation: :vertical, range: 0..100, connector: :x
      }
      vbox {
        label text: 'Units'
        slider orientation: :vertical, range: 1..16, connector: :units
      }
      vbox {
        label text: 'Angle'
        # Note that the range is integers only. Weird?
        slider orientation: :vertical, range: [-1000, 1000], connector: :angle100
      }
      canvas {
        area 0, 0, 100, 100
        scale 2
        background 204
        empty {
          translation {
             x connector: :x
             y 0
          }
          pen color: [0, 153]
          replicate {
            count connector: :units
# the question is how do I change the pen?
# Same as brushcolor: a gross hack in replicator?
# Stepper is back then. And if I perform the step before the matrix operation runs
# I can even fool move the translation.
# The problem still is that using a simple step on a painter I can no longer
# use datafields or animations.
# And setting pen and brush on the painter has no effect at all on the line, as it
# got its own version.
# So we have to do a step-operation on that line then.
# take brushcolor, split, change hue, put back in control.
# But after the 'count' steps the brush has changed for the next round as well.
# So need a copy as restore point.
            line from: [0, 0], to: [0, 8]
            rotation -> data { data.angle100 / 100.0 }
            translation 0, 8
            translate_first
=begin
  PROBLEMS: the original line's pen has still 0.0 widthF.

  second: the screen is not updated correctly as the replicator has no sense
  of the hacked pens, and does not understand they need more space.

  third: the CPU load gets 100%!

            step do |replicator, n|  # called with binding of Qt::GraphicsItem for ALL items in the replicate.
                # for each step of the replication process, except the first
              p = pen
              p.widthF = replicator.containing_form.model.units - n + 1
              self.pen = p
            end
=end
          } # replicate
        } #empty
      } # canvas
    } # hbox
  }
}
