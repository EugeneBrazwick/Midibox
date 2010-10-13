# encoding: utf-8

# Copyright (c) 2010 Eugene Brazwick

# qtruby version of charmap mainwindow example widget
# Based on Nokia example http://doc.qt.nokia.com/4.6/widgets-charactermap.html

=begin
 ****************************************************************************
 **
 ** Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies).
 ** All rights reserved.
 ** Contact: Nokia Corporation (qt-info@nokia.com)
 **
 ** This file is part of the examples of the Qt Toolkit.
 **
 ** $QT_BEGIN_LICENSE:LGPL$
 ** Commercial Usage
 ** Licensees holding valid Qt Commercial licenses may use this file in
 ** accordance with the Qt Commercial License Agreement provided with the
 ** Software or, alternatively, in accordance with the terms contained in
 ** a written agreement between you and Nokia.
 **
 ** GNU Lesser General Public License Usage
 ** Alternatively, this file may be used under the terms of the GNU Lesser
 ** General Public License version 2.1 as published by the Free Software
 ** Foundation and appearing in the file LICENSE.LGPL included in the
 ** packaging of this file.  Please review the following information to
 ** ensure the GNU Lesser General Public License version 2.1 requirements
 ** will be met: http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html.
 **
 ** In addition, as a special exception, Nokia gives you certain additional
 ** rights.  These rights are described in the Nokia Qt LGPL Exception
 ** version 1.1, included in the file LGPL_EXCEPTION.txt in this package.
 **
 ** GNU General Public License Usage
 ** Alternatively, this file may be used under the terms of the GNU
 ** General Public License version 3.0 as published by the Free Software
 ** Foundation and appearing in the file LICENSE.GPL included in the
 ** packaging of this file.  Please review the following information to
 ** ensure the GNU General Public License version 3.0 requirements will be
 ** met: http://www.gnu.org/copyleft/gpl.html.
 **
 ** If you have questions regarding the use of this file, please contact
 ** Nokia at qt-info@nokia.com.
 ** $QT_END_LICENSE$
 **
 ****************************************************************************
=end

require 'reform/widgets/mainwindow'

module Reform

  class QCharMapMainWindow < Qt::MainWindow
    private
    def initialize parent = nil
      super
      centralWidget = Qt::Widget.new
      fontLabel = Qt::Label.new tr('Font:')
      fontCombo = Qt::FontComboBox.new
      sizeLabel = Qt::Label.new tr('Size:')
      @sizeCombo = Qt::ComboBox.new
      styleLabel = Qt::Label.new tr('Style:')
      @styleCombo = Qt::ComboBox.new
      fontMergingLabel = Qt::Label.new tr('Automatic Font Merging:')
      fontMerging = Qt::CheckBox.new
      fontMerging.checked = true
      scrollArea = Qt::ScrollArea.new
      require_relative 'character_widget'
      characterWidget = QCharacterWidget.new(self)
      scrollArea.widget = characterWidget
      findStyles fontCombo.currentFont
      findSizes fontCombo.currentFont
      @lineEdit = Qt::LineEdit.new
      clipboardButton = Qt::PushButton.new tr('&To clipboard')
      @clipboard = Qt::Application::clipboard
      connect(fontCombo, SIGNAL('currentFontChanged(QFont)'), self, SLOT('findStyles(QFont)'))
      connect(fontCombo, SIGNAL('currentFontChanged(QFont)'), self, SLOT('findSizes(QFont)'))
      connect(fontCombo, SIGNAL('currentFontChanged(QFont)'), characterWidget, SLOT('updateFont(QFont)'))
      connect(@sizeCombo, SIGNAL('currentIndexChanged(QString)'), characterWidget, SLOT('updateSize(QString)'));
      connect(@styleCombo, SIGNAL('currentIndexChanged(QString)'), characterWidget, SLOT('updateStyle(QString)'));
      connect(characterWidget, SIGNAL('characterSelected(QString)')) do |ch|
        tag "characterSelected(utf-8) >=> insertCharacter(#{ch.encoding})"
        ch.force_encoding('utf-8') # ARRGH
        insertCharacter(ch)
        # encoding goes 'pufff'
      end
      connect(clipboardButton, SIGNAL(:clicked), self, SLOT(:updateClipboard));
      connect(fontMerging, SIGNAL('toggled(bool)'), characterWidget, SLOT('updateFontMerging(bool)'));

      controlsLayout = Qt::HBoxLayout.new;
      controlsLayout.addWidget(fontLabel);
      controlsLayout.addWidget(fontCombo, 1);
      controlsLayout.addWidget(sizeLabel);
      controlsLayout.addWidget(@sizeCombo, 1);
      controlsLayout.addWidget(styleLabel);
      controlsLayout.addWidget(@styleCombo, 1);
      controlsLayout.addWidget(fontMergingLabel);
      controlsLayout.addWidget(fontMerging, 1);
      controlsLayout.addStretch(1);

      lineLayout = Qt::HBoxLayout.new
      lineLayout.addWidget(@lineEdit, 1);
      lineLayout.addSpacing(12);
      lineLayout.addWidget(clipboardButton);

      centralLayout = Qt::VBoxLayout.new
      centralLayout.addLayout(controlsLayout);
      centralLayout.addWidget(scrollArea, 1);
      centralLayout.addSpacing(4);
      centralLayout.addLayout(lineLayout);
      centralWidget.setLayout(centralLayout);

      setCentralWidget(centralWidget);
      setWindowTitle(tr("Character Map"));
    end

    def findStyles(font)
      fontDatabase = Qt::FontDatabase.new
      currentItem = @styleCombo.currentText();
      @styleCombo.clear();

      fontDatabase.styles(font.family()).each do |style|
        @styleCombo.addItem(style);
      end

      styleIndex = @styleCombo.findText(currentItem);
      if (styleIndex == -1)
        @styleCombo.setCurrentIndex(0);
      else
        @styleCombo.setCurrentIndex(styleIndex);
      end
    end

    def findSizes(font)
      fontDatabase = Qt::FontDatabase.new
      currentSize = @sizeCombo.currentText();
      @sizeCombo.blockSignals(true);
      @sizeCombo.clear();

      if (fontDatabase.isSmoothlyScalable(font.family(), fontDatabase.styleString(font)))
        Qt::FontDatabase::standardSizes().each do |size|
          @sizeCombo.addItem(Qt::Variant.new(size).toString());
          @sizeCombo.setEditable(true);
        end
      else
        fontDatabase.smoothSizes(font.family(), fontDatabase.styleString(font)).each do |size|
          @sizeCombo.addItem(Qt::Variant.new(size).toString());
          @sizeCombo.setEditable(false);
        end
      end
      @sizeCombo.blockSignals(false);
      sizeIndex = @sizeCombo.findText(currentSize);
      if (sizeIndex == -1)
        @sizeCombo.setCurrentIndex([0, @sizeCombo.count() / 3].max);
      else
        @sizeCombo.setCurrentIndex(sizeIndex);
      end
    end

    protected

    def insertCharacter(character)
      tag "insertCharacter.encoding = #{character.encoding}"
      @lineEdit.insert(character);
    end

    def updateClipboard()
      @clipboard.setText(@lineEdit.text(), Qt::Clipboard::Clipboard);
      @clipboard.setText(@lineEdit.text(), Qt::Clipboard::Selection);
    end

    public

    slots 'findStyles(QFont)', 'findSizes(QFont)', :updateClipboard, 'insertCharacter(QString)'

  end # QCharMapMainWindow

  createInstantiator File.basename(__FILE__, '.rb'), QCharMapMainWindow, MainWindow, form: true
end # module Reform
