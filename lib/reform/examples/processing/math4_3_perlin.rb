
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
#=begin
      canvas {
        parameters :canvas
        perlin geometry: [0, 0, 100, 100], increment: 0.04, seed: the_seed, octave: 2, contrast: 1.4
      }
      canvas {
        parameters :canvas
        perlin geometry: [0, 0, 100, 100], increment: 0.08, seed: the_seed, octave: 2
      }
      canvas {
        parameters :canvas
        perlin {
          geometry 0, 0, 100, 100
          persistence 0.7
          increment 0.2
          seed the_seed
          octave 6
          smoothing true
          contrast 2.0
        }
      }
#=end
      canvas {
        # NOTE: the increment is too small so we interpolate at most 4x4 random values.
        # the average is 0.75 by coincedense.
        parameters :canvas
        perlin geometry: [0, 0, 100, 100], increment: 0.01, seed: the_seed, octave: 4, contrast: 1.9
      }
#=begin
      canvas {
        parameters :canvas
        perlin geometry: [0, 0, 100, 100], increment: 0.02, seed: the_seed, octave: 4
      }
      canvas {
        parameters :canvas
        perlin geometry: [0, 0, 100, 100], increment: 0.05, seed: the_seed, octave: 4, contrast: 2.5
      }
#=end
    }
  }
}

