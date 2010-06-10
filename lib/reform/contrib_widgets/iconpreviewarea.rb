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

# Copyright (c) 2010 Eugene Brazwick

module Reform

  class QIconPreviewArea < Qt::Widget
    NumModes = 4
    NumStates = 2

    private
    def initialize parent
      super
      mainLayout = Qt::GridLayout.new
      self.layout = mainLayout
      stateLabels = createHeaderLabel(tr("Off")), createHeaderLabel(tr("On"))
      raise unless NumStates == 2

      modeLabels = createHeaderLabel(tr("Normal")), createHeaderLabel(tr("Active")),
                   createHeaderLabel(tr("Disabled")), createHeaderLabel(tr("Selected"))
      raise unless NumModes == 4

      (0...NumStates).each do |j|
        mainLayout.addWidget(stateLabels[j], j + 1, 0)
      end
      @pixmapLabels = []
      (0...NumModes).each do |i|
        @pixmapLabels[i] = []
        mainLayout.addWidget(modeLabels[i], 0, i + 1)
        (0...NumStates).each do |j|
          @pixmapLabels[i][j] = createPixmapLabel
          mainLayout.addWidget(@pixmapLabels[i][j], j + 1, i + 1)
        end
      end
    end

    def createHeaderLabel text
      label = Qt::Label.new(tr("<b>%s</b>") % text)
      label.alignment = Qt::AlignCenter
      label
    end

    def createPixmapLabel
      label = Qt::Label.new
      label.enabled = false
      label.alignment = Qt::AlignCenter
      label.frameShape = Qt::Frame::Box
      label.setSizePolicy(Qt::SizePolicy::Expanding, Qt::SizePolicy::Expanding)
      label.backgroundRole = Qt::Palette::Base
      label.autoFillBackground = true
      label.setMinimumSize(132, 132)
      label
    end

    def updatePixmapLabels
      (0...NumModes).each do |i|
        mode = case i
          when 0 then Qt::Icon::Normal
          when 1 then Qt::Icon::Active
          when 2 then Qt::Icon::Disabled
          else Qt::Icon::Selected
        end
        (0...NumStates).each do |j|
          state = j == 0 ? Qt::Icon::Off : Qt::Icon::On
          pixmap = icon.pixmap(size, mode, state)
          @pixmapLabels[i][j].pixmap = pixmap
          @pixmapLabels[i][j].enabled = !pixmap.null?
        end
      end
    end

    public

    def icon= icon
      @icon = icon
      updatePixmapLabels
    end

    def size= size
      unless @size == size
        @size = size
        updatePixmapLabels
      end
    end


  end

  createInstantiator File.basename(__FILE__, '.rb'), QIconPreviewArea

end