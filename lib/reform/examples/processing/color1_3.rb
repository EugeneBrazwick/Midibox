
require 'reform/app'

Reform::app {
  form {
    grid {
      columns 4
      parameters :canvas do
        sizeHint 230
        scale 2
          # NOTE: pensize is default 0 (cosmetic)
          # As a result, scaling in on these amateur-gradients shows single lines
          # and the illusion is destroyed.
          # That's because our canvas has a logical size and uses logical pixels.
          # Fortunately 'reform' supports Qt gradients.
        area [0, 0, 100, 100]
      end
      canvas { # changing hue
        parameters :canvas
        for i in 0..100
          line from: [i, 0], to: [i, 100], stroke: hsb(i.norm(0.0, 100.0), 1.0, 1.0)
           # same as:
#           line from: [i, 0], to: [i, 100], stroke: hsb(i.norm(0.0, 100.0))
        end
      } # canvas
      canvas { # changing saturation
        parameters :canvas
        for i in 0..100
          line from: [i, 0], to: [i, 100], stroke: hsb(0.55, i.norm(0.0, 100.0), 0.85)
          # Note that 'hsb/hsv' is a color value and not the same as the 'color' attribute of brushes.
          # So it represents:  stroke: { color: hsb(...) }
          # and is similar to: stroke: [r,g,b]
        end
      } # canvas
      canvas { # changing the value/brightness
        parameters :canvas
        for i in 0..100
          line from: [i, 0], to: [i, 100], stroke: hsv(0.55, 0.4, i.norm(0.0, 100.0))
        end
      } # canvas
=begin
      canvas { # changing the saturation + value. IMPORTANT: this takes a minute, to calculate the 10000 points.
               # ruby grows to 77MB RES.
               # and a RASTER is clearly visible. FIXME: use rectangles iso circles. Does not help, fill is still empty???
BROKEN: ALL BLACK
        parameters :canvas
        STDERR.print "Please wait, while calculating...."
        for i in 0..100
          v = i.norm(0.0, 100.0)
          for j in 0..100
            point at: [i, j], stroke: hsv(0.55, j.norm(0.0, 100.0), v)
          end
        end
        STDERR.puts "Done"
      } # canvas
=end
      canvas { # changing the hue
        parameters :canvas
        for i in 0..100
          n = i.norm(0.0, 100.0)
          line from: [i, 0], to: [i, 100], stroke: [n.lerp(0.25, 0.55), n.lerp(0.6, 0.8), n.lerp(0.85, 0.251)]
        end
      } # canvas
      canvas { # changing the hue through hsv
        parameters :canvas
        for i in 0..100
          n = i.norm(0.0, 100.0)
          line from: [i, 0], to: [i, 100], stroke: hsv(n.lerp(0.65, 0.3), 0.7, 0.8)
        end
      } # canvas
      canvas {
        parameters :canvas
        pen :none
        background '#818257'
        square geometry: [17,17,66], fill: '#AEDD3C'
      } # canvas
    } # grid
  } # form
}# app