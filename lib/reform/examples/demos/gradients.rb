
require 'reform/app'

Reform::app {
  # autoform will not work (broken?) but we need a whenShown to apply the style
  form {
    title tr('Gradients')
    structure name: :data,
              value: { gradientType: Qt::LinearGradientPattern,
                       spreadMethod: Qt::Gradient::PadSpread,
                       stops: [[0.00, Qt::Color::fromRgba(0xff000000)],
                               [1.00, Qt::Color::fromRgba(0xffffffff)]],
                       defaults: [ { stops: [Qt::GradientStop.new(0.00, Qt::Color::fromRgba(0xff000000)),
                                             Qt::GradientStop.new(1.00, Qt::Color::fromRgba(0xffffffff))],
                                     spreadMethod: Qt::Gradient::PadSpread,
                                     gradientType: Qt::LinearGradientPattern }, # 0 == 4 (!)
                                   { stops: [Qt::GradientStop.new(0.00, Qt::Color::fromRgba(0x00000000)),
                                             Qt::GradientStop.new(0.04, Qt::Color::fromRgba(0xff131360)),
                                             Qt::GradientStop.new(0.08, Qt::Color::fromRgba(0xff202ccc)),
                                             Qt::GradientStop.new(0.42, Qt::Color::fromRgba(0xff93d3f9)),
                                             Qt::GradientStop.new(0.51, Qt::Color::fromRgba(0xffb3e6ff)),
                                             Qt::GradientStop.new(0.73, Qt::Color::fromRgba(0xffffffec)),
                                             Qt::GradientStop.new(0.92, Qt::Color::fromRgba(0xff5353d9)),
                                             Qt::GradientStop.new(0.96, Qt::Color::fromRgba(0xff262666)),
                                             Qt::GradientStop.new(1.00, Qt::Color::fromRgba(0x00000000))],
                                     spreadMethod: Qt::Gradient::RepeatSpread,
                                     gradientType: Qt::LinearGradientPattern }, # 1
                                   { stops: [Qt::GradientStop.new(0.00, Qt::Color::fromRgba(0xffffffff)),
                                             Qt::GradientStop.new(0.11, Qt::Color::fromRgba(0xfff9ffa0)),
                                             Qt::GradientStop.new(0.13, Qt::Color::fromRgba(0xfff9ff99)),
                                             Qt::GradientStop.new(0.14, Qt::Color::fromRgba(0xfff3ff86)),
                                             Qt::GradientStop.new(0.49, Qt::Color::fromRgba(0xff93b353)),
                                             Qt::GradientStop.new(0.87, Qt::Color::fromRgba(0xff264619)),
                                             Qt::GradientStop.new(0.96, Qt::Color::fromRgba(0xff0c1306)),
                                             Qt::GradientStop.new(1.00, Qt::Color::fromRgba(0x00000000))],
                                     spreadMethod: Qt::Gradient::PadSpread,
                                     gradientType: Qt::RadialGradientPattern }, # 2
                                   { stops: [Qt::GradientStop.new(0.00, Qt::Color::fromRgba(0x00000000)),
                                             Qt::GradientStop.new(0.10, Qt::Color::fromRgba(0xffe0cc73)),
                                             Qt::GradientStop.new(0.17, Qt::Color::fromRgba(0xffc6a006)),
                                             Qt::GradientStop.new(0.46, Qt::Color::fromRgba(0xff600659)),
                                             Qt::GradientStop.new(0.72, Qt::Color::fromRgba(0xff0680ac)),
                                             Qt::GradientStop.new(0.92, Qt::Color::fromRgba(0xffb9d9e6)),
                                             Qt::GradientStop.new(1.00, Qt::Color::fromRgba(0x00000000))],
                                     spreadMethod: Qt::Gradient::PadSpread,
                                     gradientType: Qt::ConicalGradientPattern } # 3
                                  ] # defaults
                     }
    hbox { #mainLayout
      gradientrenderer { # renderer, actually arthurframe but, well.....
        name :renderer
        sizeHint 400
      }
      groupbox { #mainGroup
        title tr('Gradients')
        fixedWidth 180
        vbox  { #mainGroupLayout
          group { #editorGroup
            title tr('Color Editor')
            vbox {
              gradienteditor { name :editor
                connector :stops
              }
              button text: tr('Reset')
            }
          }
          group { # typeGroup
            title tr('Gradient Type')
            connector :gradientType
            vbox {
              # these values could also be symbols, like :linear  (more ruby like)  FIXME
              radiobutton text: tr('Linear Gradient'), value: Qt::LinearGradientPattern
              radiobutton text: tr('Radial Gradient'), value: Qt::RadialGradientPattern
              radiobutton text: tr('Conical Gradient'), value: Qt::ConicalGradientPattern
            }
          }
          group { # spreadGroup
            title tr('Spread Method')
            connector :spreadMethod
            vbox {
              # these values could also be symbols, like :linear  (more ruby like)  FIXME
              radiobutton text: tr('Pad Spread'), value: Qt::PadSpread
              radiobutton text: tr('Reflect Spread'), value: Qt::ReflectSpread
              radiobutton text: tr('Repeat Spread'), value: Qt::RepeatSpread
            }
          }
          group { # defaults
            title tr('Defaults')
            hbox {
              button text: '1'
              button text: '2'
              button text: '3'
            }
          }
          # FIXME:
          #stretch
          # should be shortcut for:
          spacer stretch: 1
          button text: tr('Show Source')
          button text: tr("What's This?"), checkable: true
        } # mainGroupLayout
      } # mainGroup
    } # mainLayout
    whenShown do
      h_off = renderer.width / 10
      v_off = renderer.height / 8
      pts = [ Qt::PointF.new(renderer.width / 2, renderer.height / 2),
              Qt::PointF.new(renderer.width / 2 - h_off, renderer.height / 2 - v_off)]
      data.hoverpoints = pts
      # NOTE: QArthurStyle does an attempt to inherit Qt::WindowStyle
      # but the 'windows' style seems to return Qt::CommonStyle
#       require_relative 'arthur'
#       tag "ArthurStyle!"              MAYBE ???
#       style = Reform::QArthurStyle.new # NOT GOING TO WORK...
# SO LINK IT THEN....  make arthur.so or move to 'internals'...
=begin
      style = Qt::StyleFactory::create('Plastique')
      tag "Style = #{style}"
#      ["Oxygen", "Windows", "Motif", "CDE", "Plastique", "GTK+", "Cleanlooks"]  the full list here...
      find(Reform::Widget) do |w|
        tag "w=#{w}, respond_to?(:style=) = #{w.respond_to?(:style=)}"
        if w.respond_to?(:style=)
          w.style = style
          w.setAttribute(Qt::WA_AcceptTouchEvents)
        end
      end
=end
    end # whenShown
  }  # form
}