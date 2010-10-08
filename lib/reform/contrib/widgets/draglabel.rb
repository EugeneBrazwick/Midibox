
module Reform

  require 'Qt'
  require 'reform/controls/label'

#   class DragLabel < Label
#     private
#       define_simple_setter text
#   end

  class QDragLabel < Qt::Label

    private
      def initialize parent, text = nil
        super(parent)
        @labelText = ''
        self.text = text if text
      end

    public
      def text= text
        return if text === @labelText
        metric = Qt::FontMetrics.new(font());
        size = metric.size(Qt::TextSingleLine, text);

        image = Qt::Image.new(size.width() + 12, size.height() + 12,
                              Qt::Image::Format_ARGB32_Premultiplied);
        image.fill(Qt::qRgba(0, 0, 0, 0));

        font = Qt::Font.new
        font.setStyleStrategy(Qt::Font::ForceOutline);

        gradient = Qt::LinearGradient.new(0, 0, 0, image.height()-1);
        gradient.setColorAt(0.0, Qt::Color.new(Qt::white));
        gradient.setColorAt(0.2, Qt::Color.new(200, 200, 255));
        gradient.setColorAt(0.8, Qt::Color.new(200, 200, 255));
        gradient.setColorAt(1.0, Qt::Color.new(127, 127, 200));

        painter = Qt::Painter.new
        painter.begin(image);
        begin
          painter.setRenderHint(Qt::Painter::Antialiasing);
          painter.setBrush(Qt::Brush.new(gradient));
          painter.drawRoundedRect(Qt::RectF.new(0.5, 0.5, image.width()-1, image.height()-1),
                                  25, 25, Qt::RelativeSize);

          painter.setFont(font);
          painter.setBrush(Qt::Brush.new(Qt::Color.new(Qt::black)));
          painter.drawText(Qt::Rect.new(Qt::Point.new(6, 6), size), Qt::AlignCenter, text);
        ensure
          painter.end();
        end

        setPixmap(Qt::Pixmap::fromImage(image));
        @labelText = text;
      end

      def text
        @labelText
      end
  end

  createInstantiator File.basename(__FILE__, '.rb'), QDragLabel #DragLabel

end

__END__

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

