=begin
/****************************************************************************
 **
 ** Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies).
 ** All rights reserved.
 ** Contact: Nokia Corporation (qt-info@nokia.com)
 **
 ** This file is part of the demonstration applications of the Qt Toolkit.
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

module Reform

  require_relative 'shadewidget'

  class QGradientRenderer < QWidget # note, was 'ArthurFrame'
    private

      def initialize parent
        super
        @stops = []
        @hoverPoints = HoverPoints.new(self, :circle)
        @hoverPoints.pointSize = Qt::Size.new(20, 20)
        @hoverPoints.connectionType = nil
        @hoverPoints.editable = false
        @hoverPoints.points = [Qt::PointF.new(100, 100), Qt::PointF.new(200, 200)]
        @spread = Qt::Gradient::PadSpread
        @gradientType = Qt::LinearGradientPattern
      end

    public
      def paint p
        pts = @hoverPoints.points
        case @gradientType
        when Qt::LinearGradientPattern
          g = Qt::LinearGradient.new(pts[0], pts[1])
        when Qt::RadialGradientPattern
          g = Qt::RadialGradient.new(pts[0], [width, height].min / 2.0, pts[1])
        else
          l = Qt::LineF.new(pts[0], pts[1])
          angle = l.angle(Qt::LineF.new(0, 0, 1, 0))
          angle = 360 - angle if l.dy > 0
          g = Qt::ConicalGradient.new(pts[0], angle)
        end
        @stops.each do |stop|
          g.setColorAt(stop.first, stop.second)
        end
        g.setSpread(@spread)
        p.brush = Qt::Brush.new(g)
        p.pen = Qt::Pen.new(Qt::NoPen)
        p.drawRect(rect)
      end

      def sizeHint
        Qt::Size.new(400, 400);
      end

      attr :hoverPoints

#       def mousePressEvent e
#         setDescriptionEnabled(false)          # FIXME: needs ArthurFrame
#       end

      def setPadSpread()
        @spread = Qt::Gradient::PadSpread;
        update();
      end

      def setRepeatSpread()
        @spread = Qt::Gradient::RepeatSpread;
        update();
      end

      def setReflectSpread()
        @spread = Qt::Gradient::ReflectSpread;
        update();
      end

      def setLinearGradient()
        @gradientType = Qt::LinearGradientPattern;
        update();
      end

      def setRadialGradient()
        @gradientType = Qt::RadialGradientPattern;
        update();
      end

      def setConicalGradient()
        @gradientType = Qt::ConicalGradientPattern;
        update();
      end

      def gradientStops= stops
        @stops = stops
        update
      end

      slots 'gradientStops=(const QGradientStops &)', 'setPadSpread()', 'setRepeatSpread()',
            'setReflectSpread()', 'setLinearGradient()', 'setRadialGradient()', 'setConicalGradient()'
  end

  createInstantiator File.basename(__FILE__, '.rb'), QGradientRenderer

end
