require 'reform/app'

Path = File.dirname(__FILE__)

Reform::app {
  form {
    grid {
      columns 3
      parameters :canvas do
        sizeHint 230
        scale 2
        area [0, 0, 100, 100]
      end
      canvas {
        parameters :canvas
        # strangely the image does not cause the area to increase.
        # I think this is a Qt bug
        # After all there is no 'setSize' or anything.
        image src: Path + '/images/processing-js-watz.jpg'
      }
      canvas {
        parameters :canvas
        image geometry: [20, 20, 60], src: Path + '/images/processing-js-watz.jpg'
      }
      canvas {
        # note that Qt's 'colorize' differs from processing's 'tint'.
        # It also gives a noticeable aliasing (blockyness)
        parameters :canvas
        image src: Path + '/images/processing-js-watz.jpg', tint: 102
        image src: Path + '/images/processing-js-watz.jpg', at: [50, 0]
      }
      canvas {
        parameters :canvas
        image src: Path + '/images/processing-js-watz.jpg', tint: [0, 153, 204]
        image src: Path + '/images/processing-js-watz.jpg', at: [50, 0]
      }
      canvas {
        parameters :canvas
        image src: Path + '/images/processing-js-watz.jpg', tint: yellow
        image src: Path + '/images/processing-js-watz.jpg', at: [33.3, 0], tint: green
        image src: Path + '/images/processing-js-watz.jpg', at: [66.7, 0], tint: 'tan'
      }
      canvas {
        parameters :canvas
        background blue
        # giving the 'colorize' an alpha will work
        image src: Path + '/images/processing-js-watz.jpg', tint: [255, 102]
        image src: Path + '/images/processing-js-watz.jpg', at: [20, 20], tint: [255, 204, 0, 153]
      }
      canvas {
        parameters :canvas
        background white
        # giving the 'colorize' an alpha will work
        for i in 0...10
          image at: [i * 10, 0], src: Path + '/images/processing-js-watz.jpg', tint: [255, 51]
        end
      }
    }
  }
}
