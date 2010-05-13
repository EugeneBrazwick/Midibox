#!/usr/bin/ruby

require_relative '../../app'

Reform::app {
  canvas {
    scene {
      area -110.0, -110.0, 220.0, 220.0 # topleft + size(!) NOT rightbottom !!
      line { stroke red
        from -100, 0
        to 100, 0
      }
      line { stroke 'steelblue'
        from 0, -100
        to 0, 100
      }
      fill red # changes the default fill of all contained object, even before this
          # declaration (or at least, that is supposed to happen)
          # It is not the 'current' fill, but the 'default' fill.
          # otherwise there would be the temptation to use it in a procedural way;
          # fill red; circle {...} ; fill blue; circle {...};
          # Must be: circle {fill red; ...}; circle {fill blue; ...};
#       tag "calling Scene::duplicate()"
# trace do
#       circle { position 0, 0; radius 20; fill blue }
      replicate {
        rotation 1.0/60.0 # degrees, rotation around 0,0
#         translation 10.0, 0
        fillhue_rotation 1.0/60.0
#         count 10
        # the resulting matrices are now applied count times on the contained objects
        circle {
          position 0, -100
          radius 5
          # setting a fill here would override the fillhue in duplicate and the fill in scene.
        }
        # it should be possible to nest duplicates properly.
      } # replicate
      polygon { #hourHand
        points [7, 8], [-7, 8], [0, -40]
        fill 127, 0, 127
      }
      polygon { #minuteHand
        points [7, 8], [-7, 8], [0, -70]
        fill 127, 127, 191
      }
# end
    } # scene
    #antialiasing true   this is the default
    autoscale # : TODO. View must rescale on resize so the area is in full view (but keep aspectratio)
    title tr('Analog Clock')
    size 400, 400
  }
}