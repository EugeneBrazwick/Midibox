# encoding: utf-8

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
        enigma font {
#  ??          family 'Ænigma Scrawl 4 BRK Regular'
          family 'Almonte Snow'
          ptsize 32
        }
      }
      canvas {
        parameters :canvas
        fill blue       # used, a la processing
        stroke red # not used!
        simpletext at: [0, 40], text: 'LAX', font: :enigma
#         simpletext at: [0, 70], text: 'AMS', font: 'Helvetica'
#         simpletext at: [0, 100], text: 'FRA', font: 'Helvetica'
      } # canvas
      canvas {
        parameters :canvas
#         simpletext at: [0, 40], text: 'LAX' #, font: 'Helvetica'
      } # canvas
    }
  }  # form
}