#!/usr/bin/ruby

# Copyright (c) 2010-2011 Eugene Brazwick
# Based on Nokia example http://doc.qt.nokia.com/4.6/widgets-charactermap.html

# Solution nr 2 uses only 1 contrib widget

require 'reform/app'

Reform::app {
  mainwindow {
    windowTitle tr('Character Map')
    # the term 'widget' is used for non-containers only.
    # But a 'frame' is a pure widget as well, except it can have components
    frame {
      # the model connected to this form is the 'font' itself
      central
      vbox { # vcentralWidget.setLayout(centralLayout);
        #centralLayout
        #centralLayout.addLayout(controlsLayout);
        hbox {  #controlsLayout = Qt::HBoxLayout.new;
          label text: tr('Font:') # fontLabel
          fontcombo {
            connector :self    #good idea ????
            stretch 1
          }
          label text: tr('Size:') #sizeLabel);
          combobox {
            stretch 1
            modelconnector :sizes  # use font.sizes as model source
            connector :pointSize # and set font.pointSize when changed
          }
          label text: tr('Style:') # styleLabel);
          combobox {
            stretch 1
            modelconnector :styles
            connector :styleString # and NOT :style!!!
          }
          label text: tr('Automatic Font Merging:')
          checkbox { # fontMerging = Qt::CheckBox.new
            checked true
            stretch 1
	    connector :fontMerging
          } # fontMerging
          spacer stretch: 1
        } # controlsLayout
        scrollarea { #scrollArea
          # TODO scrollArea.widget = characterWidget
          character_widget { # characterWidget
            whenCharacterSelected { |ch| lineEdit.insert ch }
          }
        } # scrollArea
        spacer spacing: 4
#         centralLayout.addLayout(lineLayout);
        hbox { #           lineLayout = Qt::HBoxLayout.new
          edit { # lineLayout.addWidget(@lineEdit, 1);
            name :lineEdit
          }
          spacer spacing: 12
          button { # clipboardButton
            text tr('&To clipboard')
            whenClicked do
              cb = Qt::Application::clipboard
              text = lineEdit.text
              tag "#{cb}.setText('#{text}'), Clipboard + Selection"
              cb.setText text, Qt::Clipboard::Clipboard
              cb.setText text, Qt::Clipboard::Selection
            end
          } # clipboardButton
        } # lineLayout
      } # centralLayout
    } # centralWidget
#     tag "END OF MAINWINDOW, fontCombo.current font = #{fontCombo.current.family}"
    # FIXME: it stays FreeSans forever. Also it selects DejaVuSans in the combo!!! (somehow)
    #  I get it, the fontcombo ALWAYS starts with DejaVuSans.... It ignores the outside model completely!
    font_model family: 'FreeSans'
#     fontCombo.whenActivated
  } # mainWindow
}
