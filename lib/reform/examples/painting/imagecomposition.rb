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
    # load the image and make sure it becomes 'ResultSize' big, also it MUST become a pickmap
    # since the result is assigned to @resultImage or @sourceImage! (????)
    def loadImage fileName, button
      image = Qt::Image.new(fileName)
#       tag "image.load(#{fileName})"
#       image.load fileName
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
#       tag "assigning pixmap to button.icon, size = #{fixedImage.width}x#{fixedImage.height}"
      button.icon = fixedImage
#       pixmap
    end

    def chooseImage title, button
      fileName = Qt::FileDialog::getOpenFileName(@qtc, title)
      if fileName.empty? then nil else loadImage(fileName, button) end
    end

    def chooseSource
      @sourceImage = chooseImage(tr('Choose Source Image'), sourceButton)
      operatorCombo.whenActivated
    end

    def chooseDestination
      @destinationImage = chooseImage(tr('Choose Destination Image'), destinationButton)
      operatorCombo.whenActivated
    end

    def recalculateResult currentMode
#       tag "recalc, source=#{@sourceImage.width}x#{@sourceImage.height}"
#       tag "recalc, dest=#{@destinationImage.width}x#{@destinationImage.height}"
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
#       tag "recalculated result, #{@resultImage.width}x#{resultImage.height}"
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
        whenClicked { chooseSource }
      }
      combobox {
        name :operatorCombo
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
        whenActivated { |index| recalculateResult(index) }
      }
      toolbutton {
        name :destinationButton
        iconSize ResultSize
        layoutpos 2, 0
        rowspan 3
        whenClicked { chooseDestination }
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
      @sourceImage = loadImage(dir + '/images/butterfly.png', sourceButton)
      @destinationImage = loadImage(dir + '/images/checker.png', destinationButton)
       operatorCombo.whenActivated            #   Too  soon ?
#     end
  }
}

__END__
Constant        Value   Description
QPainter::CompositionMode_SourceOver            0       This is the default mode. The alpha of the source is used to
                                                        blend the pixel on top of the destination.
QPainter::CompositionMode_DestinationOver       1       The alpha of the destination is used to blend it on top of the
                                                        source pixels. This mode is the inverse of
                                                        CompositionMode_SourceOver.
QPainter::CompositionMode_Clear                 2       The pixels in the destination are cleared (set to fully
                                                        transparent) independent of the source.
QPainter::CompositionMode_Source                3       The output is the source pixel. (This means a basic copy
                                                        operation and is identical to SourceOver when the source pixel
                                                        is opaque).
QPainter::CompositionMode_Destination           4       The output is the destination pixel. This means that the
                                                        blending has no effect. This mode is the inverse of
                                                        CompositionMode_Source.
QPainter::CompositionMode_SourceIn              5       The output is the source, where the alpha is reduced by that
                                                        of the destination.
QPainter::CompositionMode_DestinationIn         6       The output is the destination, where the alpha is reduced by
                                                        that of the source. This mode is the inverse of
                                                        CompositionMode_SourceIn.
QPainter::CompositionMode_SourceOut             7       The output is the source, where the alpha is reduced by the
                                                        inverse of destination.
QPainter::CompositionMode_DestinationOut        8       The output is the destination, where the alpha is reduced by
                                                        the inverse of the source. This mode is the inverse of
                                                        CompositionMode_SourceOut.
QPainter::CompositionMode_SourceAtop            9       The source pixel is blended on top of the destination, with
                                                        the alpha of the source pixel reduced by the alpha of the
                                                        destination pixel.
QPainter::CompositionMode_DestinationAtop       10      The destination pixel is blended on top of the source, with
                                                        the alpha of the destination pixel is reduced by the alpha of
                                                        the destination pixel. This mode is the inverse of
                                                        CompositionMode_SourceAtop.
QPainter::CompositionMode_Xor                   11      The source, whose alpha is reduced with the inverse of the
                                                        destination alpha, is merged with the destination, whose
                                                        alpha is reduced by the inverse of the source alpha.
                                                        CompositionMode_Xor is not the same as the bitwise Xor.
QPainter::CompositionMode_Plus                  12      Both the alpha and color of the source and destination
                                                        pixels are added together.
QPainter::CompositionMode_Multiply              13      The output is the source color multiplied by the destination.
                                                        Multiplying a color with white leaves the color unchanged,
                                                        while multiplying a color with black produces black.
QPainter::CompositionMode_Screen                14      The source and destination colors are inverted and then
                                                        multiplied. Screening a color with white produces white,
                                                        whereas screening a color with black leaves the color unchanged.
QPainter::CompositionMode_Overlay               15      Multiplies or screens the colors depending on the destination
                                                        color. The destination color is mixed with the source color to
                                                        reflect the lightness or darkness of the destination.
QPainter::CompositionMode_Darken                16      The darker of the source and destination colors is selected.
QPainter::CompositionMode_Lighten               17      The lighter of the source and destination colors is selected.
QPainter::CompositionMode_ColorDodge            18      The destination color is brightened to reflect the source
                                                        color. A black source color leaves the destination color
                                                        unchanged.
QPainter::CompositionMode_ColorBurn             19      The destination color is darkened to reflect the source color.
                                                        A white source color leaves the destination color unchanged.
QPainter::CompositionMode_HardLight             20      Multiplies or screens the colors depending on the source color.
                                                        A light source color will lighten the destination color,
                                                        whereas a dark source color will darken the destination color.
QPainter::CompositionMode_SoftLight             21      Darkens or lightens the colors depending on the source color.
                                                        Similar to CompositionMode_HardLight.
QPainter::CompositionMode_Difference            22      Subtracts the darker of the colors from the lighter. Painting
                                                        with white inverts the destination color, whereas painting
                                                        with black leaves the destination color unchanged.
QPainter::CompositionMode_Exclusion             23      Similar to CompositionMode_Difference, but with a lower contrast.
                                                        Painting with white inverts the destination color, whereas
                                                        painting with black leaves the destination color unchanged.
QPainter::RasterOp_SourceOrDestination          24      Does a bitwise OR operation on the source and destination
                                                        pixels (src OR dst).
QPainter::RasterOp_SourceAndDestination         25      Does a bitwise AND operation on the source and destination
                                                        pixels (src AND dst).
QPainter::RasterOp_SourceXorDestination         26      Does a bitwise XOR operation on the source and destination
                                                        pixels (src XOR dst).
QPainter::RasterOp_NotSourceAndNotDestination   27      Does a bitwise NOR operation on the source and destination
                                                        pixels ((NOT src) AND (NOT dst)).
QPainter::RasterOp_NotSourceOrNotDestination    28      Does a bitwise NAND operation on the source and destination
                                                        pixels ((NOT src) OR (NOT dst)).
QPainter::RasterOp_NotSourceXorDestination      29      Does a bitwise operation where the source pixels are inverted
                                                        and then XOR'ed with the destination ((NOT src) XOR dst).
QPainter::RasterOp_NotSource                    30      Does a bitwise operation where the source pixels are
                                                        inverted (NOT src).
QPainter::RasterOp_NotSourceAndDestination      31      Does a bitwise operation where the source is inverted and
                                                        then AND'ed with the destination ((NOT src) AND dst).
QPainter::RasterOp_SourceAndNotDestination      32      Does a bitwise operation where the source is AND'ed with
                                                        the inverted destination pixels (src AND (NOT dst)).
