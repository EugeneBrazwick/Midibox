
require 'reform/app'

# Using the same, but inherently different approach.
Reform::app {
  form {
    grid {
      columns 3
      parameters :canvas do
        sizeHint 220
        scale 2
        area [0, 0, 100, 100]
        background gray
        pen color: black #, weight: 2
      end
      the_seed = 3327
      canvas {
        parameters :canvas
        marble geometry: [0, 0, 100, 100], seed: the_seed, octave: 2, contrast: 1.4
      }
      canvas {
        parameters :canvas
        marble geometry: [0, 0, 100, 100], seed: the_seed, octave: 2, density: 32
      }
      canvas {
        parameters :canvas
        marble geometry: [0, 0, 100, 100], seed: the_seed, octave: 2, density: 128
      }
    }
  }
}

