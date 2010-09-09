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

require 'reform/app'

# let's patch it instead of polluting contrib_widgets...
module Reform

  require_relative '../../controls/widget'
  # using QWidget iso Qt;:Widget makes sizeHint work! (and nothing much more)
  # We now follow renderarea.cpp
  class QRenderArea < QWidget
  private
    def initialize parent
      super
      @shape = :Polygon;
      @pen = Qt::Pen.new
      @brush = Qt::Brush.new
      @antialiased = true;
      @transformed = false;
      @pixmap = Qt::Pixmap.new
      @pixmap.load(File.dirname(__FILE__) + "/../images/qt-logo.png");
      setBackgroundRole(Qt::Palette::Base);
      setAutoFillBackground(true);
    end
  public
    def shape= sym
      @shape = sym
      update
    end

    def pen= aPen
      @pen = aPen
      update
    end

    def brush= aBrush
      @brush = aBrush
      update
    end

    def antialiased= val
      @antialiased = val
      update
    end

    def transformed= val
      @transformed = val
      update
    end

    def paintEvent event
      painter = nil
      points = [ Qt::Point.new(10, 80), Qt::Point.new(20, 10), Qt::Point.new(80, 30),
                 Qt::Point.new(90, 70) ];
      rect = Qt::Rect.new(10, 20, 80, 60);
      startAngle = 20 * 16;
      arcLength = 120 * 16;
      painter = Qt::Painter.new(self);
      painter.setPen(@pen);
      painter.setBrush(@brush);
      if (@antialiased)
        tag "antialiased!!!"
        painter.setRenderHint(Qt::Painter::Antialiasing, true);
      end
      x = 0
      while x < width()
        y = 0
        while y < height()
          painter.save();
          begin
            painter.translate(x, y);
            if (@transformed)
              painter.translate(50, 50);
              painter.rotate(60.0);
              painter.scale(0.6, 0.9);
              painter.translate(-50, -50);
            end
            case @shape
            when :Line
              painter.drawLine(rect.bottomLeft(), rect.topRight());
            when :Points
              painter.drawPoints(points, 4);
            when :Polyline
              painter.drawPolyline(points, 4);
            when :Polygon
              painter.drawPolygon(Qt::Polygon.new(points));
            when :Rect
              painter.drawRect(rect);
            when :RoundedRect
              painter.drawRoundedRect(rect, 25, 25, Qt::RelativeSize);
            when :Ellipse
              painter.drawEllipse(rect);
            when :Arc
              painter.drawArc(rect, startAngle, arcLength);
            when :Chord
              painter.drawChord(rect, startAngle, arcLength);
            when :Pie
              painter.drawPie(rect, startAngle, arcLength);
            when :Path
              path = Qt::PainterPath.new
              path.moveTo(20, 80);
              path.lineTo(20, 30);
              path.cubicTo(80, 0, 50, 50, 80, 80);
              painter.drawPath(path);
            when :Text
              painter.drawText(rect, Qt::AlignCenter, tr("Qt by\nNokia"));
            when :Pixmap
              painter.drawPixmap(10, 10, @pixmap);
            end
          ensure
            painter.restore();
          end
          y += 100
        end
        x += 100
      end
      painter.setRenderHint(Qt::Painter::Antialiasing, false);
      painter.setPen(palette().dark().color());
      painter.setBrush(Qt::NoBrush);
      painter.drawRect(Qt::Rect.new(0, 0, width() - 1, height() - 1));
    ensure
      painter and painter.end
    end

    # setShape can no longer be a slot I fear, since it uses a symbol...
    slots 'pen=(const QPen &pen)', 'brush=(const QBrush &brush)', 'antialiased=(bool antialiased)',
          'transformed=(bool transformed)'
  end

#   tag "createInstantiator render_area"
  registerControlClass :render_area, QRenderArea
end

Reform::app {
  title tr('Basic Drawing')
  gridlayout { # mainLayout
    col(0) { stretch }
    col(3) { stretch }
    row(1) { minimumHeight 6 }
    row(8) { minimumHeight 8 }
    render_area {
      colspan 4
      sizeHint 400, 200
      minimumSize 100, 100
      # Now 'shape' is a simple switch that decides the visibility of the contents.
    }
    combobox { # shapeComboBox
      layoutpos 2, 2
      model Polygon: tr('Polygon'), Rect: tr('Rectangle'), RoundedRect: tr('Rounded Rectangle'),
            Ellipse: tr('Ellipse'),
            Pie: tr('Pie'), Chord: tr('Chord'), Path: tr('Path'), Line: tr('Line'),
            Polyline: tr('Polyline'),
            Arc: tr('Arc'), Points: tr('Points'), Text: tr('Text'), Pixmap: tr('Pixmap')
      labeltext tr('&Shape:')
    }
    spinbox { # penWidthSpinBox
      layoutpos 2, 3
      range 0, 20
      specialValueText tr('0 (cosmetic pen)')
      labeltext tr('Pen &Width:')
    }
    combobox { # penStyleComboBox
      layoutpos 2, 4
      model Qt::SolidLine=>tr('Solid'), Qt::DashLine=>tr('Dash'), Qt::DotLine=>tr('Dot'),
            Qt::DashDotLine=>tr('Dash Dot'), Qt::DashDotDotLine=>tr('Dash Dot Dot'),
            Qt::NoPen=>tr('None')
      labeltext tr('&Pen Style:')
    }
    combobox { # penCapComboBox
      layoutpos 2, 5
      model Qt::FlatCap=>tr('Flat'), Qt::SquareCap=>tr('Square'), Qt::RoundCap=>tr('Round')
      labeltext tr('Pen &Cap:')
    }
    combobox { # penJoinComboBox
      layoutpos 2, 6
      model Qt::MiterJoin=>tr('Miter'), Qt::BevelJoin=>tr('Bevel'), Qt::RoundJoin=>tr('Round')
      labeltext tr('Pen &Join:')
    }
    combobox { # brushStyleComboBox
      layoutpos 2, 7
      model Qt::LinearGradientPattern=>tr('Linear Gradient'), Qt::RadialGradientPattern=>tr('Radial Gradient'),
            Qt::ConicalGradientPattern=>tr('Conical Gradient'), Qt::TexturePattern=>tr('Texture'),
            Qt::SolidPattern=>tr('Solid'), Qt::HorPattern=>tr('Horizontal'), Qt::VerPattern=>tr('Vertical'),
            Qt::CrossPattern=>tr('Cross'), Qt::BDiagPattern=>tr('Backward Diagonal'),
            Qt::FDiagPattern=>tr('Forward Diagonal'), Qt::DiagCrossPattern=>tr('Diagonal Cross'),
            Qt::Dense1Pattern=>tr('Dense 1'),
            Qt::Dense2Pattern=>tr('Dense 2'),
            Qt::Dense3Pattern=>tr('Dense 3'),
            Qt::Dense4Pattern=>tr('Dense 4'),
            Qt::Dense5Pattern=>tr('Dense 5'),
            Qt::Dense6Pattern=>tr('Dense 6'),
            Qt::Dense7Pattern=>tr('Dense 7'),
            Qt::NoBrush=>tr('None')
      labeltext tr('&Brush Style:')
    }
    label { # otherOptionsLabel
      layoutpos 1, 9
      layout_alignment :right
      text tr('Other Options:')
    }
    checkbox { # antialiasingCheckBox
      text tr('&Antialiasing')
      checked true
    }
    checkbox { # transformationsCheckBox
      layoutpos 2, 10
      text tr('&Transformations')
    }
  }
}
