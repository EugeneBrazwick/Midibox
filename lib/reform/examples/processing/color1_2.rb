require 'reform/app'

Reform::app {
  form {
    grid {
      columns 3
      parameters :canvas do
        sizeHint 230
        scale 2
        area [0, 0, 100, 100]
      end
      define {
        ruby brush 211, 24, 24, 160
        pink brush 237, 159, 176
      }
      canvas {
        parameters :canvas
        stroke :none
        background black
        circle center: [47, 36], radius: 32, fill: [242, 204, 47, 160]
        circle center: [90, 47], radius: 32, fill: [174, 221, 60, 160]
        circle center: [57, 79], radius: 32, fill: [116, 193, 206, 160]
      } # canvas
      canvas {
        parameters :canvas
        stroke :none
        background white
        circle center: [47, 36], radius: 32, fill: [242, 204, 47, 160]
        circle center: [90, 47], radius: 32, fill: [174, 221, 60, 160]
        circle center: [57, 79], radius: 32, fill: [116, 193, 206, 160]
      } # canvas
      canvas {
        parameters :canvas
        background :pink
        stroke :none
        rect geometry: [35, 0, 20, 100], brush: { color: :ruby }
        # this examples creates a new brush, just to show you can use the color.
        # Normally, you would say:
        rect geometry: [75, 0, 20, 100], brush: :ruby
      } # canvas
    } # grid
  } # form
}# app