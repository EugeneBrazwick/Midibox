require 'reform/app'

Reform::app {
  form {
    grid {
      columnCount 3
      parameters :canvas do
        sizeHint 230
        area [0, 0, 100, 100]
        scale 2
        background 'hotpink'
      end
      canvas {
        parameters :canvas
        rect geo: [55, 0, 30, 45]
        empty {
          rotate 22.5
          rect geo: [55, 0, 30, 45]
        }
      } # canvas
      canvas {
        parameters :canvas
        rect geo: [10, 60, 70, 20]
        empty {
          rotate -11.25
          rect geo: [10, 60, 70, 20]
          empty {
            rotate -22.5
            rect geo: [10, 60, 70, 20]
          } # empty
        } # empty
      } # canvas
      canvas {
        parameters :canvas
        circle center: [32, 32], radius: 15
        pen weight: 1
        empty {
          scale 1.8
          circle center: [32, 32], radius: 15
        } # empty
      } # canvas
      canvas {
        parameters :canvas
        pen weight: 1
        circle center: [32, 32], radius: 15
        empty {
          scale 2.8, 1.8
          circle center: [32, 32], radius: 15
        } # empty
      } # canvas
      canvas {
        parameters :canvas
        pen weight: 1
        rect geo: [10, 20, 70, 20]
        empty {
          scale 1.7
          rect geo: [10, 20, 70, 20]
          empty {
            scale 1.7
            rect geo: [10, 20, 70, 20]
          } # empty
        } # empty
      } # canvas
      canvas {
        parameters :canvas
        circle center: [32, 32], radius: 15
        empty {
          scale 1.8
          circle center: [32, 32], radius: 15
        } # empty
      } # canvas
    }
  }
}

