
# Code taken from Nokia examples at http://doc.trolltech.com/4.6/opengl-2dpainting.html

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

$HACK_opengl = false

# PATCH FOR qt4.4.2
module Qt
  class Application < Qt::Base
    def exec
      method_missing(:exec)
      # See problems below. if OpenGL is used and also a nondefault font is used
        # with drawtext, then BANG.. SEGV in 'dispose'.
      self.dispose unless $HACK_opengl
      Qt::Internal.application_terminated = true
    end
  end
end

module Reform

  module QOpenGL # namespacing a bit
    class QGLWidget < Qt::GLWidget
    private
      def initialize helper, parent
        $HACK_opengl = true
        super(Qt::GLFormat.new(Qt::GL::SampleBuffers | Qt::GL::AlphaChannel), parent)
        @helper = helper
        @elapsed = 0
        setFixedSize 200, 200
        setAutoFillBackground false
      end

    public

      def paintEvent event
        painter = Qt::Painter.new(self)
        painter.renderHint = Qt::Painter::Antialiasing
        @helper.paint(painter, event, @elapsed)
      ensure
        painter.end
      end

      def animate
        @elapsed = (@elapsed + sender.interval) % 1000
        repaint
      end

      slots 'animate()'
    end

    class Q2DPaintingWidget < Qt::Widget
    private
      def initialize helper, parent
        super(parent)
        @helper, @elapsed = helper, 0
        setFixedSize 200, 200
      end

    public

      def paintEvent event
        painter = Qt::Painter.new(self)
        painter.renderHint = Qt::Painter::Antialiasing
        @helper.paint(painter, event, @elapsed)
      ensure
#         painter.pen = nil
#         painter.brush = nil
        painter.end
      end

      def animate
        @elapsed = (@elapsed + sender.interval) % 1000
        repaint
      end

      slots 'animate()'
    end

    class Helper
    private
      def initialize
        gradient = Qt::LinearGradient.new(Qt::PointF.new(50, -20), Qt::PointF.new(80, 20))
        gradient.setColorAt(0.0, Qt::Color.new(Qt::white))
        gradient.setColorAt(1.0, Qt::Color.new(0xa6, 0xce, 0x39))
        @background = Qt::Brush.new(Qt::Color.new(64, 32, 64))
        @circleBrush = Qt::Brush.new(gradient)
        @circlePen = Qt::Pen.new(Qt::Color.new(Qt::black))
        @circlePen.width = 1
        @textPen = Qt::Pen.new(Qt::Color.new(Qt::white))
        @textFont = Qt::Font.new # ('helvetica')#  default font
#         @textFont = Qt::Font.new('Helvetica', 26)       # also crashes!!!!
        @textFont.pixelSize = 50  # Removing this fixes the SEGV!!
          # @textFont.setPointSize 20 CRASHES TOO
      end

    public
      def paint painter, event, elapsed
        painter.fillRect event.rect, @background
        painter.translate 100, 100
        painter.save
        painter.brush = @circleBrush
        painter.pen = @circlePen
        painter.rotate elapsed * 0.030
        r = elapsed / 1000.0
        i, n = 0, 30
        while i < n
          painter.rotate 30
          radius = 120.0 * ((i + r) / n)
          circleRadius = 1 + ((i + r) / n) * 20
          painter.drawEllipse(Qt::RectF.new(radius, -circleRadius, circleRadius * 2, circleRadius * 2))
          i += 1
        end
        painter.restore
#         painter.save
        painter.pen = @textPen
        # @textFont = Qt::Font.new; @textFont.pixelSize = 50            STILL SEGV at end!!!!
#         f = painter.font               DOES NOT WORK!!!
        painter.font = @textFont # .dup -> SEGV # erm...
        # after this call the destructor of qtruby app crashes. In 'dispose()'
        # BUT: not if the font is NOT set...   save+restore does not fix this...
        # AND: only if opengl version is called!
        painter.drawText(Qt::Rect.new(-50, -50, 100, 100), Qt::AlignCenter, 'Qt')
        #painter.drawText(-50, -50, 'Qt')  ALSO CRASHES
#         painter.font = f
        # painter.font = nil -> SEGV
#         painter.restore
      end
    end

    # file: window.h/cpp
    class Q2DPaintingWindow < Qt::Widget
      private
      def initialize parent
        super(parent)
        helper = Helper.new
        native = Q2DPaintingWidget.new(helper, self)
        openGL = QGLWidget.new(helper, self)
        nativeLabel = Qt::Label.new(tr('Native'))
        nativeLabel.alignment = Qt::AlignHCenter
        openGLLabel = Qt::Label.new(tr('OpenGL'))
        openGLLabel.alignment = Qt::AlignHCenter
        layout = Qt::GridLayout.new
        layout.addWidget native, 0, 0
        layout.addWidget openGL, 0, 1 if openGL
        layout.addWidget nativeLabel, 1, 0
        layout.addWidget openGLLabel, 1, 1
        setLayout layout
        timer = Qt::Timer.new(self)
        connect(timer, SIGNAL('timeout()'), native, SLOT('animate()'))
        connect(timer, SIGNAL('timeout()'), openGL, SLOT('animate()')) if openGL
        timer.start 50 # 20 frames per second
        setWindowTitle tr('2D Painting on Native and OpenGL Widgets')
      end
    end

  end
  createInstantiator File.basename(__FILE__, '.rb'), QOpenGL::Q2DPaintingWindow

end # module Reform
