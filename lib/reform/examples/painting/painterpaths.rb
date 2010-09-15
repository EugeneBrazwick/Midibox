# encoding: utf-8

# Promise to myself: make this class 100% reform.
# No callbacks
# No methods
# No contributed special widgets, just for the sake of this example
# Nice, because all those shapes must then be described using paramters alone....
# erm...

require 'reform/app' # app is all you need

# extend Reform

# I lied:
require_relative '../../graphics/painterpath'

Reform::registerControlClassProxy 'renderarea', 'examples/painting/inc/renderarea'

NumRenderAreas = 9  # 3x3

# BUGS: changing the combo's (or any control) has no effect, which seems to be a 'ruby_model' problem using OpenStruct.
# 2) the callback below is UGLY it should be possible to use 'connector' alone.

Reform::app {
  form { # the example use 'widget' but 'widget' cannot be used for internal reasons.
    title tr('Painter Paths')
    # allow the 'painterpath' instantiator method in the form itself. UGLY!
#     extend Reform::GraphicContext
    # models follow the very same syntax rules as all other controls.
    # it is not 'ruby_model VALUE' but 'ruby_model value: VALUE' or 'ruby_model { value VALUE }'
    structure value: { fillRule: Qt::OddEvenFill, fillColor1: 'mediumslateblue', fillColor2: 'cornsilk',
                       penColor: 'darkslateblue', penWidth: 1, rotationAngle: 0,
=begin
  the next question is how to create the 3x3 painterpaths and how to assign them to the
  widget. To begin with, they could be stored in any array, 3x3 or simply 9 long.
  How and where can a path be instantiated...
  A path is a graphic component and so requires GraphicContext

  A painterpath can be added to a true graphic item using an implicit convert to Qt::PolygonF.

  MEMORYLEAK alert:  the 'painterpath' method will add the painterpath as a child to our form.
  As such it will receive 'updateModel' messages. This not good. *FIXME*
=end
      painterpaths: [
                  Reform::PainterPath.new {
#                     tag "self = #{self}"
                    moveTo 20.0, 30.0
=begin
  Now I want to add a line 'as is'.
  line from: [20.0, 30.0], to: [80.0, 30.0]
  since that is what this is. But that really does not add up properly.
  We would get a lot of redundant coordinates:
    line from: [20.0, 30.0], to: [80.0, 30.0]
    line from: [80.0, 30.0], to: [80.0, 70.0]
  Also 'line' is a graphicitem, and we really don't need one here.

=end
                    lineTo 80.0, 30.0
                    lineTo 80.0, 70.0
                    lineTo 20.0, 70.0
                    close
                  },
                  Reform::PainterPath.new {
                    moveTo 80.0, 35.0
                    # x,y(center)  w,h  startangle, sweepangle (ccw)
                    arcTo 70.0, 30.0, 10.0, 10.0, 0.0, 90.0  # UGLY numeric mess!!!!
                    lineTo 25.0, 30.0
                    arcTo 20.0, 30.0, 10.0, 10.0, 90.0, 90.0
                    lineTo 20.0, 65.0
                    arcTo 20.0, 60.0, 10.0, 10.0, 180.0, 90.0
                    lineTo 75.0, 70.0
                    arcTo 70.0, 60.0, 10.0, 10.0, 270.0, 90.0
                    close
                  },
                  Reform::PainterPath.new {
                    moveTo 80.0, 50.0
                    arcTo 20.0, 30.0, 60.0, 40.0, 0.0, 360.0
                  },
                  Reform::PainterPath.new {
                    moveTo 50.0, 50.0
                    arcTo 20.0, 30.0, 60.0, 40.0, 60.0, 240.0
                    close
                  },
                  Reform::PainterPath.new {
                    moveTo 10.0, 80.0
                    lineTo 20.0, 10.0
                    lineTo 80.0, 30.0
                    lineTo 90.0, 70.0
                    close
                  },
                  Reform::PainterPath.new {
                    moveTo 60.0, 40.0
                    arcTo 20.0, 20.0, 40.0, 40.0, 0.0, 360.0
                    moveTo 40.0, 40.0
                    lineTo 40.0, 80.0
                    lineTo 80.0, 80.0
                    lineTo 80.0, 40.0
                    close
                  },
                  Reform::PainterPath.new {
                    timesFont = Qt::Font.new('Times', 50)
                    timesFont.styleStrategy = Qt::Font::ForceOutline
                    addText 10, 70, timesFont, 'Qt'
=begin                    alternative syntax:  FIXME this is better....
                    text { at 10, 70,
                           text 'Qt'
                           font 'Times', 50
                         }
=end
                  },
                  Reform::PainterPath.new {
                    moveTo 20, 30
                    cubicTo 80, 0, 50, 50, 80, 80
                  },
                  Reform::PainterPath.new {
                    moveTo 90, 50
                    for i in 1...5
                      lineTo 50 + 40 * Math.cos(0.8 * i * Math::PI), 50 + 40 * Math.sin(0.8 * i * Math::PI)
                    end
                    close
                  }
                ]
    }
    gridlayout { #mainLayout
      columnCount 4 # this saves us from ever supplying layout positions!
      gridlayout { # toplayout 3 x 3
        #connector :painterpaths # so we receive the array here . NO, we need ALL data!
        colspan :all_remaining
        columnCount 3
        # hence, repeating a component nine times will add it 3 x 3
        # for the time being:
#         for nr in 0...NumRenderAreas do               FOR is EVIL!!!
        (0...NumRenderAreas).each do |nr|
#           tag "nr = #{nr}"
          renderarea {
#             tag "renderara, qtc = #{@qtc}, must be QRenderArea"
#             tag "nr = #{nr}"
            selv = self
            whenConnected { |model, options|
#               tag "model = #{model}, qtc=#{@qtc}"
              # Oh man!!! All 'when' triggers run in the form!
              # So self is the form.  Fortunately they are also closures...
#               tag "i=#{nr}"
              selv.qtc.setData(model, model.painterpaths[nr])
            }
            backgroundRole :base
            minimumSizeHint 50, 50
            sizeHint 100, 100
=begin
  the task remaining is now the proper 'paint' instructions
  This is basically the original task of the unit painting/painterpaths/renderarea.cpp
  in the example.
=end
          }
        end
      }
      combobox { #fillRuleComboBox
        connector :fillRule
        labeltext tr('Fill &Rule:') # auto placed on the left side
        colspan :all_remaining
        model Qt::OddEvenFill=>tr('Odd Even'), Qt::WindingFill=>tr('Winding')
      }
      # How do we populate these two with colors?  Bwaah
      combobox { # fillColor1ComboBox
        connector :fillColor1
        model Qt::Color::colorNames
        labeltext tr('&Fill Gradient:')
      }
      label text: tr('to'), fixedSize: true
      combobox { # fillColor2ComboBox
        connector :fillColor2
        model Qt::Color::colorNames
      }
      spinbox { # penWidthSpinBox
        connector :penWidth
        colspan :all_remaining
        range 0..20
        labeltext tr('&Pen Width:')
      }
      combobox { # penColorComboBox
        connector :penColor
        model Qt::Color::colorNames
        colspan :all_remaining
        labeltext tr('Pen &Color:')
      }
      spinbox { # rotationAngleSpinBox
        connector :rotationAngle
        colspan :all_remaining
        range 0...360
        wrapping true
        suffix '°'
        labeltext tr('&Rotation Angle:')
      }
    }
  }
}