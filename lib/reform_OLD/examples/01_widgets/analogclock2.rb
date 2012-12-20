#!/usr/bin/ruby

require 'reform/app'

Reform::app {
  scene {
    name :clockscene
    area -110.0, -110.0, 220.0, 220.0 # topleft + size(!) NOT rightbottom !!
    fill red # changes the default fill of all contained object, even before this
        # declaration (or at least, that is supposed to happen)
        # It is not the 'current' fill, but the 'default' fill.
        # otherwise there would be the temptation to use it in a procedural way;
        # fill red; circle {...} ; fill blue; circle {...};
        # Must be: circle {fill red; ...}; circle {fill blue; ...};
#       tag "calling Scene::duplicate()"
    replicate {
      rotation 6
#       translation 11, 11
      # count would be set cleverly by 'rotation' but this is no longer so
      count 60
      step do |replicator, n|  # called with binding of Qt::GraphicsItem for ALL items in the replicate.
              # for each step of the replication process, except the first
        b = brush
        color = b.color
        hsv = color.hue, color.saturation, color.value, color.alpha
        hsv[0] = (hsv[0] + 6) % 360
        color.setHsv(*hsv)
        b.color = color
        self.brush = b
      end
      circle {
        center 100, 0
        radius 5
      }
    } # replicate
    now = Time.now
    polygon {
      name :hourHand
      points [7, 8], [-7, 8], [0, -40]
      fill 127, 0, 127
      pen :none
      rotation (now.hour + now.min / 60.0)* 30.0 # (360.0 / 12.0)
    }
    polygon {
      name :minuteHand
      points [7, 8], [-7, 8], [0, -70]
      fill 0, 127, 127, 191 # it is transparent
      pen :none
      rotation (now.min + now.sec / 60.0) * 6.0 # (360.0 / 60.0)
=begin
two things are required
- the starting position must reflect the current time
- the hand must move synchronised with the system time.
    a) by using incremental changes, every minute
    b) by always use the same method, take current time and use that.

b is obviously the most simple and robust solution. But how can we pull it off?
=end
    }
        # timer {}  .  It seems that timer.start causes the trigger to be called in the
            # timer object itself, so we must override it.
            # but then we still must tweak the receiver.
        # so the following solution is simpler:
    timer_interval(1000) {
#         tag "ARRGH, this is procedural, SNEAK!!!"  FIXME
      now = Time.now
      minuteHand.rotation (now.min + now.sec / 60.0) * 6.0
      hourHand.rotation (now.hour + now.min / 60.0)* 30.0 # (360.0 / 12.0)
    }
# end
  } # scene
  canvas {
    qscene :clockscene
    #antialiasing true   this is the default
    autoscale # View must rescale on resize so the area is in full view (but keep aspectratio)
    title tr('Analog Clock')
    sizeHint 400, 400
  }
}