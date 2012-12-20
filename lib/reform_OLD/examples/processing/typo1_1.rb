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
        almonte font {
#  ??          family 'Ænigma Scrawl 4 BRK Regular'
          family 'Almonte Snow' # NEED: sudo apt-get install ttf-larabie-deco
          ptsize 32
        }
        ubuntu font family: 'Ubuntu', ptsize: 32
        ubuntu_12 font family: 'Ubuntu', ptsize: 12
      }
      canvas {
        parameters :canvas
        fill blue       # used, a la processing
        stroke red # not used!
        simpletext at: [0, 30], text: 'LAX', font: :almonte
        simpletext at: [0, 65], text: 'AMS', font: :almonte
        simpletext at: [0, 100], text: 'FRA', font: :almonte
      } # canvas
      canvas {
        parameters :canvas
        font :ubuntu
        fill black # IMPORTANT !
        simpletext at: [0, 36], text: '19'
        simpletext at: [0, 70], text: '72'
        simpletext at: [62, 70], text: 'R'
      } # canvas
      canvas {
        parameters :canvas
        font :ubuntu_12
        fill black # this relates to 'defaultTextColor' since 'text' accepts 'rich/html' text
          # which can be styled.
          # IMPORTANT: Qt::GraphicsTextItem uses upperleft!!
        text topleft: [10, 0], width: 80, text: 'Response is the medium'
      } # canvas
      canvas {
        parameters :canvas
        font :ubuntu
        simpletext at: [0, 40], text: 'DAY', fill: white
        simpletext at: [0, 70], text: 'CVG', fill: black
        simpletext at: [0, 100], text: 'ATL', fill: 60
      } # canvas
      canvas {
        parameters :canvas
        font family: 'Ubuntu', ptsize: 72
        fill black, 160
        simpletext at: [0, 80], text: '1'
        simpletext at: [15, 80], text: '2'
        simpletext at: [30, 80], text: '3'
        simpletext at: [45, 80], text: '4'
        simpletext at: [60, 80], text: '5'
      } # canvas
      canvas {
        parameters :canvas
        font family: 'Ubuntu', ptsize: 32, style: :italic
        fill black
        simpletext at: [6, 45], text: 'GNU', font: :ubuntu
        simpletext at: [2, 80], text: 'GNU'
      } # canvas
    }
  }  # form
}