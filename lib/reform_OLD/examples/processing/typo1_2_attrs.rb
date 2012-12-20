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
        background gray
      end
      define {
        ubuntu font family: 'Ubuntu', ptsize: 32
        ubuntu_12 font family: 'Ubuntu', ptsize: 12
        ubuntu_8 font family: 'Ubuntu', ptsize: 8
      }
      canvas {
        parameters :canvas
        fill black
        font :ubuntu
        simpletext at: [0, 40], text: 'LNZ', fill: white
        # strange enough text is not printed from the baseline as with simpletext
        # but from the topleft....AAARGHH
#         text at: [0, 40], text: 'LNZ'
#         simpletext at: [0, 65], text: 'STN', scale: 1.0, fill: white
#         simpletext at: [0, 65], text: 'STN', scale: 0.9
        simpletext at: [0, 75], text: 'STN', scale: 18.0/32
#         simpletext at: [0, 65], text: 'STN', scale: 0.6, fill: 0.6
#         simpletext at: [0, 65], text: 'STN', scale: 0.45, fill: 0.45
        simpletext at: [0, 100], text: 'BOS', scale: 12.0/32
      } # canvas
      canvas {
        parameters :canvas
        font :ubuntu_12
        fill black
          # BUG: setting the offset to more negative values places it lower!!!!!!!!!!!!!!!! ??????????????
        text topleft: [0, 0], text: 'LNZ', scale: 32.0/12
        simpletext at: [0, 75], text: 'STN', scale: 1.4, fill: white
        simpletext at: [0, 75], text: 'STN', scale: 1.45
        simpletext at: [0, 75], text: 'STN', scale: 1.6, fill: magenta   # VANISHES ??? Qt  BUG!! ????
        text topleft: [0, 55], text: 'STN', scale: 18/12.0, fill: blue
        simpletext at: [0, 100], text: 'BOS'
      } # canvas
      canvas {
        parameters :canvas
        font :ubuntu_8
        fill black
        text width: 100, text: 'The internalleading cannot be changed by Qt (at least not without complex hacking).'
        # maybe using a stylesheet ?
      } # canvas
      canvas {
        parameters :canvas
        font :ubuntu_8
        fill black
        line from: [50, 0], to: [50, 100]
        # for alignment, use HTML, make sure the geometry is ok
        text topleft: [50, 20], width: 50, html: '<p align=left>Left</p>'
        text topleft: [0, 50], width: 50, html: '<p align=right>Right</p>'
        text geometry: [0, 80, 100], html: '<p align=center>Center</p>'
      } # canvas
      canvas {
        parameters :canvas
        font family: 'Ubuntu', ptsize: 32
        fill blue
        # How big is a text?
        fontmetrics = Qt::FontMetrics.new(font)
        simpletext at:[22, 38], text: 'U'
        rect geometry: [22, 40, fontmetrics.width('U'), 5]
        txt = 'UC'
        simpletext at: [22, 78], text: txt
        rect geometry: [22, 80, fontmetrics.width(txt), 5]
      } # canvas
      canvas {
        parameters :canvas
      } # canvas
    }
  }  # form
}