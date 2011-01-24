
require 'reform/app'

Width = 700
Height = 100

Reform::app {
  form {
    vbox {
      parameters :canvas do
        sizeHint 720, 110
        area [0, 0, Width, Height]
        background 'tan'
      end
      canvas {
        parameters :canvas
        fill black
        angle = 0.0
        for x in (0..Width).step(5)
          y = Math.sin(angle) * 35 + 50
          rect geometry: [x, y, 2, 4]
          angle += Math::PI / 40
        end
      }
      canvas {
        parameters :canvas
        fill black
        pen :none
        offset, scaleVal, angleInc, angle = 50.0, 35.0, Math::PI / 28, 0.0
        for x in (0..Width).step(5)
          y = offset + Math.sin(angle) * scaleVal
          rect geometry: [x, y, 2, 4]
          angle += angleInc
        end
      }
      canvas {
        parameters :canvas
        pen :none
        offset, scaleVal, angleInc, angle = 50.0, 20.0, Math::PI / 18, 0.0
        for x in (0..Width).step(5)
          y = offset + Math.sin(angle) * scaleVal
          rect geometry: [x, y, 2, 4], fill: white
          y = offset + Math.cos(angle) * scaleVal
          rect geometry: [x, y, 2, 4], fill: black
          angle += angleInc
        end
      }
      canvas {
        parameters :canvas
        offset, scaleVal, angleInc, angle = 50.0, 30.0, Math::PI / 56, 0.0
        shape {
          # build triangle_strip without creating an array
          triangle_strip Enumerator.new { |yielder|
            for x in (4..(Width + 5)).step(5)
              y = Math.sin(angle) * scaleVal
              yielder << [x, if x.even? then offset + y else offset - y end] #.tap{|t| tag "t=#{t.inspect}"}
              angle += angleInc
            end
          } # triangle_strip
        } # shape
      } # canvas
      canvas {
        parameters :canvas
        offset, scaleVal, angleInc, angle = 126.0, 126.0, 0.42, 0.0
        for x in (-52..Width).step(5)
          y = offset + Math.sin(angle) * scaleVal
          line from: [x, 0], to: [x+50, Height], stroke: { weight: 2.0, color: y.round }
          angle += angleInc
        end
      }
=begin          We need a button to activate this...
    Takes a minute and 90MB and renders slowly.
    Also the load gets 100% when partially covered.
    But it looks OK.

      canvas {
        parameters :canvas
        fill 255, 20
        scaleVal, angleInc, angle = 18.0, Math::PI / 28, 0.0
        for offset in (-10...(Width+10)).step(5)
          for y in (0..Height).step(2)
            x = offset + Math.sin(angle) * scaleVal
            ellipse geometry: [x, y, 10], pen: :none
            point at: [x, y], pen: black
            angle += angleInc
          end
          angle += Math::PI
        end
      }
=end
    }
  }
}