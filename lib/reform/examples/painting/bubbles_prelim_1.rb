#!/usr/bin/ruby

require 'reform/app'

Reform::app {
  mainwindow {
      #svg width="20cm" height="15cm" viewBox="0 0 800 600"
    sizeHint 800, 600
#     xmlns="http://www.w3.org/2000/svg"
#     xmlns:xlink="http://www.w3.org/1999/xlink/"
#     baseProfile="tiny" version="1.2">
    title tr('Spheres')
    #  Semi-transparent bubbles on a colored background.</desc>
    canvas {
      scene {
        # Create radial gradients for each bubble. EXPERIMENTAL
        define { # like the svg 'def' section
          blueBubble brush {
            # alternative syntax:               brush :blueBubble do ....
            radialgradient { # id="blueBubble" gradientUnits="userSpaceOnUse"
                        #cx="0" cy="0" center 0,0
                        #r="100" radius
                        # fx="-50" fy="-50"> focal point
              center 0, 0
              radius 50
              focalpoint -25
              stop offset: 0.0, color: :white
              stop offset: 0.25, color: [205, 205, 255, 166]
              stop offset: 1.0, color: [205, 170, 205, 192]
            } # blueBubble
          }
        }
=begin
  I think of something better.
  That whole define section is worthless. At least for brushes.
  If a complex brush is defined, like a specific gradient then we could pass the name
  when defined.  Just like actions can be named and then used elsewhere!
=end

        fill :blueBubble        # DOES NOT WORK
        circle position: [50, 100] # DOES NOT WORK
        circle position: [100, 100], fill: :blueBubble # DOES NOT WORK
        circle {
          position 150, 200
          radius 400
          fill radialgradient {
            center 150, 100
            radius 150
=begin            # my idea was that this was with respect to the painted item, coordinates
void QAbstractGraphicsShapeItem::setBrush ( const QBrush & brush )
Sets the item's brush to brush.
The item's brush is used to fill the item.
If you use a brush with a QGradient, the gradient is relative to the item's coordinate system.
See also brush().

But 150, 100 is the CENTER. and Qt uses upperleft...
NO, It is clear to see that changing the position of the circle leaves the radial in its
place. This is BAD!!

AARGHHHH This is not gonna work!!
=end
            focalpoint 160, 140
            stop offset: 0.0, color: :white
            stop offset: 0.25, color: [205, 150, 255, 66]
            stop offset: 1.0, color: [205, 170, 30, 192]
          }
        }
      }
    }
  }
}