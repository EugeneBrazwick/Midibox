
require 'reform/app'

Reform::app {
  form {
    sizeHint 280 * 3, 235 * 1
    grid {
      columnCount 3
      # there is a 'hack' that makes 'parameters :setup {' possible as well!! It's a bit ugly
      # so maybe I find something better.
      parameters :setup do
        sizeHint 230
        area [0, 0, 100, 100]
        scale 2
        background gray
      end
      canvas {
        parameters :setup
        line from: [20, 20], to: [80, 20]
        stroke size: 6
        line from: [20, 40], to: [80, 40]

=begin
    PROBLAMATIC STUFF.
      Canvas::pen delegates to Scene::pen which basically calls 'make_pen'.
      GraphicsItem::pen however, uses a hash or block as indicator to generate an dynamic pen
      (actually just the color of it).

      so
        1) canvas.stroke works different then graphicsitem.stroke
        2) can a pen become a dynamic attribute by itself?

      answer: problematic.
      Conclusion: dynamics should be done on the proper level. In this case the color!

      And
          pen { size 6 }
      is the same as
          pen { size: 6 }

amazing that ruby solves these 'ambiguities'.

=end
        # NOTE: the default cap is different than the one in 'processing'.
        line from: [20, 70], to: [80, 70], stroke: { size: 18 }
      } # canvas
      canvas {
        parameters :setup
=begin
  This is wrong. You cannot override a part of a pen...
        pen weight: 12
        line from: [20, 30], to: [80, 30], stroke: { cap: :round }
        line from: [20, 50], to: [80, 50], stroke: { cap: :square }
        line from: [20, 70], to: [80, 70], stroke: { cap: :project }
=end
        w = 12
        line from: [20, 30], to: [80, 30], stroke: { weight: w, cap: :round }
        # note that 'processing' calls this 'square', but Qt::SquareCap is the same as 'project'.
        # :flat will not draw the full endpoint, while :project (==:square) does
        line from: [20, 50], to: [80, 50], stroke: { weight: w, cap: :flat }
        line from: [20, 70], to: [80, 70], stroke: { weight: w, cap: :project }
      } # canvas
      canvas {
        parameters :setup
        w = 12
        rect topleft: [12, 33], size: [15, 33], stroke: { weight: w, join: :bevel }
        rect topleft: [42, 33], size: [15, 33], stroke: { weight: w, join: :miter }
        rect topleft: [72, 33], size: [15, 33], stroke: { weight: w, join: :round }
      } # canvas
    }
  }
}