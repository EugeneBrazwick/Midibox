
# there are no drawingmodes in 'reform'
# however:


require 'reform/app'

Reform::app {
  form {
    sizeHint 280 * 2, 235 * 1
    grid {
      columnCount 2
      parameters :setup do
        sizeHint 230
        area [0, 0, 100, 100]
        scale 2
        background gray
        stroke :none
      end
      canvas {
        parameters :setup
        circle center: [33, 33], radius: 60, fill: darkGray
        circle geometry: [33, 33, 60], fill: white
        # topleft must be used with bottomright and be in front of it...
        circle topleft: [33, 33], bottomright: [60, 60], fill: black
        # It is also possible to use qtcircle and qtellispse. These have the origin in
        # the topleft corner (outside the ellipse). This is weird.
      }
      canvas {
        parameters :setup
        square geometry: [40, 40, 60], fill: darkGray
        # There is no center mode here.
        # It would be inconvenient as people probably expect the origin to be there too, ie
        # it should rotate around the center.
        # I believe it should be possible to create objects that have a rotational mapping
        # onto themselves as a single object, passing radius + angle + repeatcount.
        # a square has a radius of 'r' and a repeatcount of 4.
        #centeredsquare center: [40, 40], size: 60              Maybe later
        square topleft: [40, 40], bottomright: [60, 60], fill: black
      }
    }
  }
}
