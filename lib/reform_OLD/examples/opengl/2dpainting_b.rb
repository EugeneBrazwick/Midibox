
require 'reform/app'

Reform::app {
  title tr('2D Painting Demo attempt. Currently failing')
    # 50 ms seems OK for my eyes at least
  time_model { updatetime_ms 50; frequency 1/60.0 }
  gridlayout {
    columnCount 2
    canvas  {
      name :myCanvas
      antialiasing true
      fixedSize 210
      whenConnected do |time, options| # callback is executed by the form, not the control.
        # this is bit UGLY. There should be a better way of connecting time.angle to canvas.rotation... FIXME
        # Maybe if a connector is a hash, like name=>name.  But that conflicts with the blockform {|model| ... }
        myCanvas.rotation = time.angle # degrees  around the center of the canvas. Ignores scenes center,
            # However, since it adepts the view, this is very hard to tell. If the canvas autotranslates
            # then it may rotate around the scenes center as well. ?? That would seem the logical way to do things, won't it?
      end
      scene {
        # Without an area the canvas has some freedom of deciding what fragment to show
        # Therefore changing the coordinates does not seem to work properly,
#         area -110, -110, 220  # this sets the translation, but not the scale. It is still pixels
        area -100, -100, 200  # this sets the translation, but not the scale. It is still pixels
#         size 200 # this does setSceneRect(0, 0, 200, 200). Nevertheless the canvas shows -10, -10 as upper left.
        # circle has a white fill by default, and not transparent
        circle {
          position 10, 10  # of the CENTER! and relative to the parent (should)
          radius 50
          circle {
=begin HOWEVER, Qt doc state the following:
  Child coordinates are relative to the parent's coordinates.
  If the child is untransformed, the difference between a child coordinate and a parent coordinate is the same as
  the distance between the items in parent coordinates. For example: If an untransformed child item is positioned
  precisely in its parent's center point, then the two items' coordinate systems will be identical. If the child's
  position is (10, 0), however, the child's (0, 10) point will correspond to its parent's (10, 10) point.
=end
            position 30, 30
            radius 20
            fillcolor :blue
          }
          # Q: will this be a relative pos, and if so, rel. to what?
          # A: no. To say it simple: the coord.system of the parent is used.
          simpletext text: '30, 30', position: [30, 30]
        }
        # later ones are painted over the previous defined
        circle position: [50, 30], radius: 25, fill: :red
        simpletext text: '30, 30', position: [30, 30]
        simpletext text: '75, 75', position: [75, 75]
        simpletext text: '0, 0' # , position: [0, 0]
        simpletext text: '100, 0', position: [100, 0]
        simpletext text: '0, 100', position: [0, 100]
      }
    }
    glwidget {
      fixedSize 210
      autoFillBackground false
    }
    label {
      alignment :hcenter
      text tr('Native')
    }
    label {
      alignment :hcenter
      text 'OpenGL'
    }
  }
}
