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

require 'reform/widget'

module Reform
  class QCircleWidget < QWidget
  private
    def initialize(parent)
      super;
      @floatBased = false;
      @antialiased = false;
      @frameNr = 0;
      setBackgroundRole(Qt::Palette::Base);
      setSizePolicy(Qt::SizePolicy::Expanding, Qt::SizePolicy::Expanding);
    end

  public
    def floatBased=(floatBased)
      @floatBased = floatBased;
      update();
    end

    def antialiased=(antialiased)
      @antialiased = antialiased;
      update();
    end

    def minimumSizeHint()
      Qt::Size.new(50, 50);
    end

    def sizeHint()
      Qt::Size.new(180, 180);
    end

    def nextAnimationFrame()
      @frameNr += 1
      update();
    end

    def paintEvent(event)
      painter = Qt::Painter.new(self);
      painter.setRenderHint(Qt::Painter::Antialiasing, @antialiased);
      painter.translate(width() / 2, height() / 2);
      diameter = 0;
      while diameter < 256
        delta = ((@frameNr % 128) - diameter / 2).abs;
        alpha = 255 - (delta * delta) / 4 - diameter;
        if (alpha > 0)
          painter.pen = Qt::Pen.new(Qt::Brush.new(Qt::Color.new(0, diameter / 2, 127, alpha)), 3);
          if (@floatBased)
            painter.drawEllipse(Qt::RectF.new(-diameter / 2.0, -diameter / 2.0, diameter, diameter));
          else
            painter.drawEllipse(Qt::Rect.new(-diameter / 2, -diameter / 2, diameter, diameter));
          end
        end
        diameter += 9;
      end
    ensure
      painter.end
    end

    attr :frameNr

    def frameNr= val
      @frameNr = val
      update
    end
  end

  class CircleWidget < Widget
  private
    define_simple_setter :antialiased, :floatBased, :frameNr
  public
    def updateModel model, opts = nil
#       tag "#{self}.updateModel(#{model}, qtc.frameNr = #{@qtc.frameNr})"
#       tag "connector=#{connector}"
      if (cid = connector) && model && model.model_getter?(cid)
        @qtc.frameNr = model.model_apply_getter(cid)
      end
      super
      @qtc.update
    end
  end

  createInstantiator File.basename(__FILE__, '.rb'), QCircleWidget, CircleWidget
end