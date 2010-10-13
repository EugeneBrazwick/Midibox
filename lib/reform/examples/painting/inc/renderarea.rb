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

# I LIED AGAIN!!! too much trouble for such a simple paintevent.
module Reform
  require 'reform/widget'

 #include "renderarea.h"

  class QRenderArea < QWidget

  public
    def setData(struct, path)
      @path = path.qtc
#       tag "setData, struct=#{struct.inspect}, fillRule = #{struct.fillRule}"
      @path.fillRule = struct.fillRule
      @fillColor1 = Qt::Color.new(struct.fillColor1)
      @fillColor2 = Qt::Color.new(struct.fillColor2)
      @penWidth = struct.penWidth
      @penColor = Qt::Brush.new(Qt::Color.new(struct.penColor)) # it is a string!!
      @rotationAngle = struct.rotationAngle
      gradient = Qt::LinearGradient.new(0, 0, 0, 100);
      gradient.setColorAt(0.0, @fillColor1);
      gradient.setColorAt(1.0, @fillColor2);
      @gradient = Qt::Brush.new(gradient)
      update();
    end

    # What does this do? it is a recipy of operations on the painter.
    def paintEvent event
      painter = Qt::Painter.new(self);
      painter.renderHint = Qt::Painter::Antialiasing;
      painter.scale(width() / 100.0, height() / 100.0);
      painter.translate(50.0, 50.0);
      painter.rotate(-@rotationAngle);
      painter.translate(-50.0, -50.0);

      painter.pen = Qt::Pen.new(@penColor, @penWidth, Qt::SolidLine, Qt::RoundCap, Qt::RoundJoin);
      painter.brush = @gradient;
      painter.drawPath(@path);
    ensure
      painter.end
    end
  end

  createInstantiator File.basename(__FILE__, '.rb'), QRenderArea
end