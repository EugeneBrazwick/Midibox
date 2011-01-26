
require 'reform/app'

Width = 600

Reform::app {
  form {
    vbox {
      parameters :canvas do
        sizeHint Width + 20, 110
        area [0, 0, Width, 100]
        background 'sandybrown'
      end
      canvas { # I, using crosssection of 2d perlin
        parameters :canvas
        v = 0.0
        pen :none
        Float::initPerlin 1
        fill black
        for i in (0...Width).step(4)
          rect geometry: [i, 10 + v.noise(0.0) * 70.0, 3, 20]
          v += 0.04
        end
      }
      canvas { # II, same as I but using regular 1dimensional path. Less smooth.
        parameters :canvas
        v = 0.0
        pen :none
        fill black
        Float::initPerlin 1
        for i in (0...Width).step(4)
          rect geometry: [i, 10 + v.noise * 70.0, 3, 20]
          v += 0.04
        end
      }
      canvas { # III, same as II but using 4 octaves (speed times 2**3=8)
        parameters :canvas
        v = 0.0
        pen :none
        fill black
        Float::initPerlin 1, 2.0, 4
        for i in (0...Width).step(4)
          rect geometry: [i, 10 + v.noise * 70.0, 3, 20]
          v += 0.04
        end
      }
      canvas { # IV, same as III but using increased speed (*8).
          # showing that raising the octave works a little better.
        parameters :canvas
        v = 0.0
        pen :none
        fill black
        Float::initPerlin 1
        for i in (0...Width).step(4)
          rect geometry: [i, 10 + v.noise * 70.0, 3, 20]
          v += 0.32
          # IMPORTANT: any step larger than 1.0 results in mostly unrelated data returned
          # except for a bit of smoothing.
        end
      }
    }
  }
}
