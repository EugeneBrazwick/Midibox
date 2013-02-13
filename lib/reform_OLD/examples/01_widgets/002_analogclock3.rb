
=begin
 The problems with analogclock2.rb
 the load gets 100%...
 But I only get a single timer event a second.
 Investigate -> self.brush = .... within the 'step' causes an update.
 and since it is in the paint method itself..... AARRGGHH

 Used duplicate iso replicate.
 INCONSISTENCY: 'step' is applied to created items as reform object not Qt::GraphicItem
 as replicate uses.
=end

require 'reform/app'

Reform::app {
  # This time we put a lot more in the application. 
  # Although there are actually just 2. A timer and a canvas to paint on.
  # First a 'timer'. The timer is a 'model' or a datasource. Every
  # time the data within a model changes the model instance is propagated
  # to all forms and all controls within the application.
  # In this case the model is special as it updates automatically,
  # by default every second.
  timer # updatetime: 1.seconds # 1000.ms == default
  # Next, we put a canvas here, which is required to instantiate 'graphic'
  # elements (that are not widgets)
  canvas {
    # We setup the canvas similar to the 'app' itself. We list the properties
    # and components.
    # First 'area'. This gives as a 'user' mapping of all coordinates.
    # It just mean the topleft of our canvas will represent coordinate
    # (-110, -110) while the size is 220x220 units.
    area -110.0, -110.0, 220.0, 220.0 # topleft + size(!) NOT rightbottom !!
    # Now the mysterious 'empty'. This a graphic element (a graphical) that
    # in itself does not paint anything. However, you can put components
    # in it, so it functions as a 'group' like inkscape has.
    # In this case it harbours the outer circle of my clock.
    empty {
      # Here we are at the properties list for the empty.
      # Rotation is the angle in degrees. So this is a float.
      # But the value assigned is a lambda? Well, remember that the model
      # associated with app (the 'timer' in this case) is propagated through the
      # forms and controls, and here we 'tap' into the data it supplies to retrieve 'sec'
      # Which obviously is the number of seconds within the current minute.
      # Since we must rotate 360 degrees per minute, we get our angle for the
      # empty by using sec * 6.
      rotation -> now { now.sec * 6 }
      # Another complicated graphical here. 
      # A duplicate contains a single graphical as element, but it has a recepy
      # to make more of them.
      duplicate {
	# How many items will there be:
        count 60
	# The applied rotation between each item. Again a full circle is setup
	# since count * rotation = 360
        rotation 6
	# the 'step' callback is called for each created element,
	# available as 'self'. The duplicator is passed as arg1, while the
	# sequence number is n (which ranges from 0 to 59 in our case).
        step do |duplicator, n|
          # IMPORTANT: self is the graphic item WITHIN the replicator
	  # So 'brush' is set on each item passed, and we use hue to
	  # make the colors rotate 360 degrees as well.
	  # The hsv method is available in all graphicals and creates a
	  # color out of hue, saturation and value (strength).
	  # Note that h is in degrees while s and v must be in the range
	  # 0..255.
          brush color: hsv(n * 6, 255, 255)
        end
	# Now what is to be duplicated, a circle with default pen
	# (black), and the color is set by the step above.
        circle {
	  # The center as (x, y) coordinate. The coordinates are setup by the
	  # area property above. The first is the horizontal value, the second
	  # the vertical.
          center 100, 0
	  # and the diameter of the circle will be 10 units:
          radius 5
        }
      } # replicate
    } # empty
    # Now the hour hand. It is a polygon.
    polygon {
      # 3 points like this define a triangle. The polygon
      # automatically connects the last point to the first
      points [7, 8], [-7, 8], [0, -40]
      # fill is the content color (an alias for 'brush').
      # With three integer arguments in range 0..255 it uses these
      # as red, green and blue (rgb) components to create the color
      fill 127, 0, 127
      # there is no border/boundary drawn:
      pen :none
      # timer has a method 'hour12_f' which is the number of hours where 0.0
      # is 0 and 1.0 stands for 12 o' clock. And of course, 12 * 30 is 360 once more
      rotation -> now { now.hour12_f * 30.0 }
    }
    # the minutehand is defined later, and therefor painted over the first
    # polygon
    polygon {
      points [7, 8], [-7, 8], [0, -70]
      # it is transparent, we supply rgba here, and 255 represent solid, while
      # 0 represent completely invisible
      fill 0, 127, 127, 191 
      pen :none
      rotation -> now { now.min_f * 6.0 }
    }
    # View must rescale on resize so the area is in full view (but keep aspectratio)
    # 'autoscale' is a boolean propery that can only be set to 'true' so there is
    # no need to say 'autoscale true'.
    autoscale 
    # this is the requested size in pixels, horizontal times vertical:
    sizeHint 400, 400
  } # canvas
  # Oh, a bonus property for 'app'. The title that will be in the title bar of the form.
  title tr('Analog Clock')
}

