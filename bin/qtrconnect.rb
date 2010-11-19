# encoding: utf-8

# qt version of rconnect/aconnect/kaconnect

# Copyright © 2010 Eugene Brazwick

require 'reform/app'

Reform::app {
  title tr('QtRuby Alsa Connection Tool')
  mainwindow {
    menubar {
      menu {
        title tr('&File')
        fileQuit
      }
      separator
      menu {
        title tr('&About')
        aboutQt
        action {
          title 'qtr&connect'
          whenTriggered do
             # NOTE THAT tr() destroys the encoding somehow... It ruins the copyright sign...
             # This could be fixed if Qt understood &copyright; but it doesn't...
            Qt::MessageBox::about(@qtc, tr("About QtRuby Alsa Connection Tool"),
                    tr(<<-TEXT) +
                      <p>Inspired by <b>kaconnect</b> by Matthias Nagorni, which, in its turn
                      was based on the original <b>aconnect</b> code by Takashi Iwai.</p>
                      <p>Ported to qtruby + Qt4.7 by Eugene Brazwick.</p>
                      <p>
                    TEXT
                    ' © ' + tr(<<-TEXT))
                      2010 Eugene Brazwick.</p>
                    TEXT
          end
        } # action
      } # about-menu
    } # menubar
    # Next we have a top and bottom panel, where the top is 2 row, 3 column grid.
    frame {
      vbox {
        grid {
          colcount 3
          label {
            text tr('Readable Ports:')
            font pointSize: 14
          }
          widget
          label {
            text tr('Writeable Ports:')
            font pointSize: 14
          }
          list {
            alsaportarray mode: :read
          }
          label text: 'GRAPHSTUFF'
          list {
            alsaportarray mode: :write
          }
        } # grid
        hbox {
          spacer stretch: 4
          pushbutton title: tr('connect')
          spacer stretch: 1
          pushbutton title: tr('disconnect')
          spacer stretch: 4
        } # hbox
      } # vbox
    } # frame
  } # mainwindow
} # app