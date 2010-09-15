# Same ideals apply as to painterpaths, even though we didn't realize a lot of them...

require 'reform/app'

# require 'reform/internals/reform_internals'           FAILURE
require 'yaml'

# FIXME: UGLY !
def read_pp(*paths)
  # to build images/shapes.yaml use extra/dumpshapes.cpp (see source for gcc command)
  # then run /tmp/t > examples/painting/images/shapes.yaml
  raw_polylistspaths = YAML::load_file(File::dirname(__FILE__) + '/images/shapes.yaml')
#   tag "raw_polylistspaths = #{raw_polylistspaths.inspect}"    OK
  i = 0
  paths.each do |p|
    raw_polylists = raw_polylistspaths[i] # list of polygons
    raw_polylists.each do |raw_poly|        # poly is an array of {'x','y'} tuples
      poly = []
      raw_poly.each do |pt|
        x, y = pt['x'], pt['y']
        poly << Qt::PointF.new(x, y)
      end
#       p.moveTo(poly[0].x, poly[0].y)
      p.addPolygon(Qt::PolygonF.new(poly))
#       p.closeSubpath
    end
    # It might be possible to dump the single painterpaths to a separate yaml file each.
    # reloading them is then trivial (but I have no experience with dumping Qt objects to a yamlfile)
    i += 1
  end
end

Reform::app {
  title tr('SVG Generator')
  form {
    @path = ''
    car = Qt::PainterPath.new
    house = Qt::PainterPath.new
    @tree = Qt::PainterPath.new
    @moon = Qt::PainterPath.new
    read_pp(car, house, @tree, @moon)
    @shapeMap = { car: car, house: house, tree: @tree, moon: @moon }
    structure value: { shape: :house, color: Qt::darkYellow, background: :sky }, name: :data
    sizeHint 340, 360
    gridlayout {        # gridLayout_2
      fixedSize true
      columnCount 3
      spacer { # horizontalSpacer_2
        orientation :horizontal
        space 40
      }
      widget {
        name :displayWidget
        fixedSize true
        stretch 200
        sizeHint 200
        whenConnected { |data, options| displayWidget.update }
#         def data= val           # FIXME: UGLY!
# #           @data = val         NO LONGER USEFULL
#           @qtc.update   # causes whenPainted to trigger
#         end
        whenPainted do |painter|
#           tag "whenPainted"
          painter.clipRect = Qt::Rect.new(0, 0, 200, 200)
          painter.pen = Qt::NoPen
          case data.background
          when :trees
            painter.fillRect(Qt::Rect.new(0, 0, 200, 200), Qt::darkGreen)
            painter.brush = Qt::green
            painter.pen = Qt::black
            row = 0
            (-5...250).step 50 do |y|
              row += 1
              xs = if row == 2 || row == 3 then 150 else 50 end
              (0...200).step xs do |x|
#                 puts "translate(#{x}, #{y}) and paint a tree"
                painter.save
                begin
                  painter.translate(x, y)
                  painter.drawPath(@tree)
                ensure
                  painter.restore
                end
              end
            end
            painter.brush = Qt::white
            painter.translate(145, 10)
            painter.drawPath(@moon)
            painter.translate(-145, -10)
          when :road
            painter.fillRect(Qt::Rect.new(0, 0, 200, 200), Qt::gray)
            painter.pen = Qt::Pen.new(Qt::Brush.new(Qt::white), 4.0, Qt::DashLine)
            painter.drawLine(Qt::Line.new(0, 35, 200, 35))
            painter.drawLine(Qt::Line.new(0, 165, 200, 165))
          else # ie, :sky
            painter.fillRect(Qt::Rect.new(0, 0, 200, 200), Qt::darkBlue)
            painter.translate(145, 10)
#             painter.brush = Qt::white    #    WRONG is cast to 'style'...     And it can't really change that
# since Qt::white is a Qt::Enum and so Qt::Dense3Pattern for example...
            painter.brush = Qt::white  # bwaah..
            painter.drawPath(@moon)
            painter.translate(-145, -10)
          end
          painter.brush = data.color
          painter.pen = Qt::black
          painter.translate(100, 100)
          painter.drawPath(@shapeMap[data.shape])
        end
      }
      spacer { #horizontalSpacer_3
        orientation :horizontal
        space 40
      }
      gridlayout { # gridLayout
        colspan 3
        align_labels :wide
        columnCount 2
        combobox { # shapeComboBox
          connector :shape
          labeltext tr('&Shape:')
          model house: tr('House'), car: tr('Car')
            # these are part of shape2. Patience... tree: tr('Tree'), moon: tr('Moon')
        }
        toolbutton { # colorButton
#           connector :color    THIS IS BAD MAN...
          text tr('Choose Color...')
          labeltext tr('&Color:')
          whenClicked {
            color = Qt::Color === data.color ? data.color : Qt::Color.new(data.color)
            data.color = color if (color = Qt::ColorDialog::getColor(color)).valid?
          }
        }
        combobox { # shapeComboBox_2
          connector :background
          model sky: tr('Sky'), trees: tr('Trees'), road: tr('Road')
          labeltext tr('&Background:')
        }
      } # gridLayout
      hbox { # horizontalLayout
        colspan 3
        spacer stretch: 40
        toolbutton { # toolButton_2
          text tr('Save &As...')
          whenClicked {
            newPath = Qt::FileDialog::getSaveFileName(@qtc, tr('Save SVG'), @path,
                                                      tr('SVG files (*.svg)')) or return
            @path = newPath
            generator = Qt::SvgGenerator.new
            generator.fileName = @path
            generator.size = Qt::Size.new(200, 200)
            generator.viewBox = Qt::Rect.new(0, 0, 200, 200)
            generator.title = tr('SVG Generator Example Drawing')
            generator.description = tr('An SVG drawing created by the SVG Generator ' +
                                       'Example provided with Qt.')
            displayWidget.whenPainted(generator) # paint(painter)
          }
        }
      }
    }
  }
}