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

# this is a quite literal translation of the C++ code

require_relative '../controls/widget'

module Reform
  class QCodeEditor < Qt::PlainTextEdit
    private
    def initialize parent = nil
      super
      require_relative 'linenumberarea'
      @lineNumberArea = QLineNumberArea.new(self)
      connect(self, SIGNAL('blockCountChanged(int)'), self, SLOT('updateLineNumberAreaWidth(int)'));
      connect(self, SIGNAL('updateRequest(QRect,int)'), self, SLOT('updateLineNumberArea(QRect,int)'));
      connect(self, SIGNAL('cursorPositionChanged()'), self, SLOT('highlightCurrentLine()'));
      updateLineNumberAreaWidth 0
      highlightCurrentLine
    end

    protected
    def resizeEvent e
#       tag "resizeEvent, calling super first"
      super
      cr = contentsRect
      rect = Qt::Rect.new(cr.left, cr.top, lineNumberAreaWidth, cr.height)
#       tag "setting Geo to #{rect.inspect}"
      @lineNumberArea.geometry = rect
    end

    def updateLineNumberAreaWidth newBlockCount
      setViewportMargins lineNumberAreaWidth, 0, 0, 0
    end

    def updateLineNumberArea rect, dy
      if dy != 0
        @lineNumberArea.scroll 0, dy
      else
        @lineNumberArea.update 0, rect.y, @lineNumberArea.width, rect.height
      end
      updateLineNumberAreaWidth 0 if rect.contains(viewport.rect)
    end

    def highlightCurrentLine
      extraSelections = []
      unless readOnly?
        selection = Qt::TextEdit::ExtraSelection.new
        lineColor = Qt::Color.new(Qt::yellow).lighter(160)
        selection.format.background = Qt::Brush.new(lineColor)
        selection.format.setProperty(Qt::TextFormat::FullWidthSelection, Qt::Variant.new(true))
#         tag "textCursor = #{textCursor}"
        cursor = selection.cursor = textCursor
        cursor.clearSelection
        extraSelections << selection
      end
      self.extraSelections = extraSelections
    end

    slots 'updateLineNumberAreaWidth(int)', 'updateLineNumberArea(QRect,int)', 'highlightCurrentLine()'
    public

    def lineNumberAreaWidth
      digits = 1
      max = [1, blockCount].max
      while max >= 10
        max /= 10
        digits += 1
      end
      3 + fontMetrics.width('9') * digits
#       tag "lineNumberAreaWidth -> #{r}"
#       r
    end

    def lineNumberAreaPaintEvent event
#       tag "lineNumberAreaPaintEvent"
      painter = Qt::Painter.new(@lineNumberArea)
      begin
        painter.fillRect(rect = event.rect, Qt::lightGray)
        block = firstVisibleBlock
        blockNumber = block.blockNumber
        top = Integer(blockBoundingGeometry(block).translated(contentOffset).top)
        bottom = top + Integer(blockBoundingRect(block).height)
        width, height = @lineNumberArea.width, fontMetrics.height
        painter.pen = Qt::Pen.new(Qt::black)
        while block.valid? && top <= rect.bottom
          if block.visible? && bottom >= rect.top
            painter.drawText 0, top, width, height, Qt::AlignRight, (blockNumber + 1).to_s
          end
          block = block.next
          top = bottom
          bottom = top + Integer(blockBoundingRect(block).height)
          blockNumber += 1
        end
      ensure
        painter.end
      end
#       tag "did lineNumberAreaPaintEvent"
    end # lineNumberAreaPaintEvent
  end # class QCodeEditor

  createInstantiator File.basename(__FILE__, '.rb'), QCodeEditor

end  # module Reform
