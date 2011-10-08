
# Showing that sliders can have a floating-point (actually a fixpoint) range

require 'reform/app'

Reform::app {
  form {
    sizeHint 340, 200
    struct sliderpos: 0.0
    vbox {
      slider orientation: :horizontal, range: [-10.0, 10.0], connector: :sliderpos
      edit connector: :sliderpos
    }
  }
}