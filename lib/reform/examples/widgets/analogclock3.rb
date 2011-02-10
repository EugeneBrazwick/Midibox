
=begin
 the load gets 100%...
 I only get a single timer event a second.
 investigate -> self.brush = .... within the 'step' causes an update.
 and since it is in the paint method itself..... AARRGGHH

 Used duplicate iso replicate.
 INCONSISTENCY: 'step' is applied to created items as reform object not Qt::GraphicItem
 as replicate uses.
=end

require 'reform/app'

# require 'profile'

Reform::app {
  timer # updatetime: 1.seconds # 1000.ms == default
  canvas {
    area -110.0, -110.0, 220.0, 220.0 # topleft + size(!) NOT rightbottom !!
#     fill red
    empty {
      rotation -> now { now.sec * 6 }
      duplicate {
        rotation 6
        count 60
        step do |duplicator, n|
          # IMPORTANT: self is the object(s) WITHIN the replicator
          brush color: hsv(n * 6, 255, 255)
        end
        circle {
          center 100, 0
          radius 5
        }
      } # replicate
    } # empty
    polygon {
      name :hourHand
      points [7, 8], [-7, 8], [0, -40]
      fill 127, 0, 127
      pen :none
      rotation -> now { now.hour12_f * 30.0 }
    }
    polygon {
      name :minuteHand
      points [7, 8], [-7, 8], [0, -70]
      fill 0, 127, 127, 191 # it is transparent
      pen :none
      rotation -> now { now.min_f * 6.0 }
    }
    autoscale # View must rescale on resize so the area is in full view (but keep aspectratio)
    title tr('Analog Clock')
    sizeHint 400, 400
  } # canvas
}
