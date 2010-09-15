
# Copyright (c) 2010 Eugene Brazwick

require 'reform/app'

Reform::app {
  form {
    sizeHint 270, 400
    structure value: { stops: nil }
    vbox {
      canvas {
  #       autoscale
  #       background :red
        background lineargradient stops: nil, start: [-125,0], stop: [125,0]
  #       scene {
  #         background :red # THIS WORKS
  #         background lineargradient(stops: nil)
  #       }
      }
      gradienteditor # connector: :stops
    }
  }
}