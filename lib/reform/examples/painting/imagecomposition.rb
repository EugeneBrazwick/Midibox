=begin
/****************************************************************************
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
 ****************************************************************************/
=end


# BUGS: images are not visible at all.
require 'reform/app'

Reform::app {
  title tr('Image Composition')
  form {
    def loadImage fileName, image, button
#       tag "image.load(#{fileName})"
      image.load fileName
#       tag "loaded #{image.width}x#{image.height}"
      fixedImage = Qt::Image.new(ResultSize, Qt::Image::Format_ARGB32_Premultiplied)
      painter = Qt::Painter.new(fixedImage)
      begin
        painter.compositionMode = Qt::Painter::CompositionMode_Source
        painter.fillRect(fixedImage.rect, Qt::transparent)
        painter.compositionMode = Qt::Painter::CompositionMode_SourceOver
        painter.drawImage(imagePos(image), image)
      ensure
        painter.end
      end
#       tag "assigning pixmap to button.icon"
      button.icon = Qt::Pixmap::fromImage(fixedImage)
      fixedImage
    end

    def chooseImage title, image, button
      fileName = Qt::FileDialog::getOpenFileName(@qtc, title)
      loadImage(fileName, image, button) unless fileName.empty?
    end

    def chooseSource
      @sourceImage = chooseImage(tr('Choose Source Image'), @sourceImage, sourceButton)
      recalculateResult
    end

    def chooseDestination
      @destinationImage = chooseImage(tr('Choose Destination Image'), @destinationImage, destinationButton)
      recalculateResult
    end

    def recalculateResult
      painter = Qt::Painter.new(@resultImage)
      begin
        mode = currentMode # selected combobox data
        painter.compositionMode = Qt::Painter::CompositionMode_Source
        painter.fillRect(@resultImage.rect, Qt::transparent)
        painter.compositionMode = Qt::Painter::CompositionMode_SourceOver
        painter.drawImage(0, 0, @destinationImage)
        painter.compositionMode = mode
        painter.drawImage(0, 0, @sourceImage)
        painter.compositionMode = Qt::Painter::CompositionMode_DestinationOver
        painter.fillRect(@resultImage.rect, Qt::white)
      ensure
        painter.end
      end
      resultLabel.pixmap = Qt::Pixmap::fromImage(@resultImage)
    end

    def imagePos image
      Qt::Point.new((ResultSize.width - image.width) / 2, (ResultSize.height - image.height) / 2)
    end

    ResultSize = Qt::Size.new(200, 200)
    gridlayout { #mainLayout
      toolbutton {
        name :sourceButton
        iconSize ResultSize
        rowspan 3
      }
      combobox { # operatorCombo
        layoutpos 1, 1
        model Qt::Painter::CompositionMode_SourceOver=>tr('SourceOver'),
              Qt::Painter::CompositionMode_DestinationOver=>tr("DestinationOver"),
              Qt::Painter::CompositionMode_Clear=>tr("Clear"),
              Qt::Painter::CompositionMode_Source=>tr("Source"),
              Qt::Painter::CompositionMode_Destination=>tr("Destination"),
              Qt::Painter::CompositionMode_SourceIn=>tr("SourceIn"),
              Qt::Painter::CompositionMode_DestinationIn=>tr("DestinationIn"),
              Qt::Painter::CompositionMode_SourceOut=>tr("SourceOut"),
              Qt::Painter::CompositionMode_DestinationOut=>tr("DestinationOut"),
              Qt::Painter::CompositionMode_SourceAtop=>tr("SourceAtop"),
              Qt::Painter::CompositionMode_DestinationAtop=>tr("DestinationAtop"),
              Qt::Painter::CompositionMode_Xor=>tr("Xor"),
              Qt::Painter::CompositionMode_Plus=>tr("Plus"),
              Qt::Painter::CompositionMode_Multiply=>tr("Multiply"),
              Qt::Painter::CompositionMode_Screen=>tr("Screen"),
              Qt::Painter::CompositionMode_Overlay=>tr("Overlay"),
              Qt::Painter::CompositionMode_Darken=>tr("Darken"),
              Qt::Painter::CompositionMode_Lighten=>tr("Lighten"),
              Qt::Painter::CompositionMode_ColorDodge=>tr("ColorDodge"),
              Qt::Painter::CompositionMode_ColorBurn=>tr("ColorBurn"),
              Qt::Painter::CompositionMode_HardLight=>tr("HardLight"),
              Qt::Painter::CompositionMode_SoftLight=>tr("SoftLight"),
              Qt::Painter::CompositionMode_Difference=>tr("Difference"),
              Qt::Painter::CompositionMode_Exclusion=>tr("Exclusion")
      }
      toolbutton {
        name :destinationButton
        iconSize ResultSize
        layoutpos 2, 0
        rowspan 3
      }
      label { # equalLabel
        text '='
        layoutpos 3, 1
      }
      label {
        name :resultLabel
        minimumSize ResultSize.width, 0
        layoutpos 4, 0
        rowspan 3
      }
      fixedSize true
    }
#     def postSetup             DOES NOT HELP
#       super
      dir = File.dirname(__FILE__)
      @resultImage = Qt::Image.new(ResultSize, Qt::Image::Format_ARGB32_Premultiplied)
      @sourceImage = Qt::Image.new
      @destinationImage = Qt::Image.new
      loadImage(dir + '/images/butterfly.png', @sourceImage, sourceButton)
      loadImage(dir + '/images/checker.png', @destinationImage, destinationButton)
#     end
  }
}