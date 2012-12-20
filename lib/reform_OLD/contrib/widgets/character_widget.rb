# encoding: utf-8

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

module Reform

# this widget displays a large grid with the characters within the
# associated font
  class QCharacterWidget < Qt::Widget
    private
      def initialize parent
	super
	@squareSize, @columns, @lastKey = 24, 16, -1
	@displayFont = Qt::Font.new  # sneakily hidden in .h file
	self.mouseTracking = true
      end

    public
      def updateFont font
	@displayFont.family = font.family
	@squareSize = [24, Qt::FontMetrics.new(@displayFont).xHeight * 3].max
	adjustSize
	update
      end

      def updateSize fontSize
	@displayFont.pointSize = Integer(fontSize)
	@squareSize = [24, Qt::FontMetrics.new(@displayFont).xHeight * 3].max
	adjustSize
	update
      end

      def updateStyle fontStyle
	oldStrategy = @displayFont.styleStrategy
	require_relative '../../models/font_model'
	@displayFont = Reform::FontModel.font(@displayFont.family, fontStyle, @displayFont.pointSize)
	@displayFont.styleStrategy = oldStrategy
	@squareSize = [24, Qt::FontMetrics.new(@displayFont).xHeight * 3].max
	adjustSize
	update
      end

      def updateFontMerging enable
	@displayFont.styleStrategy = enable ? Qt::Font::PreferDefault : Qt::Font::NoFontMerging
	adjustSize
	update
      end

      def sizeHint
	Qt::Size.new(@columns * @squareSize, (65536 / @columns) * @squareSize)
      end

      def mouseMoveEvent event
	widgetPosition = mapFromGlobal(event.globalPos)
	key = (widgetPosition.y / @squareSize) * @columns + widgetPosition.x / @squareSize
	text = ''
	text.force_encoding 'utf-8'
	text << "<p>Character: <span style=\"font-size: 24pt; font-family: %s\">" % [@displayFont.family] <<      +
		key <<
		"</span><p>Value: 0x" <<
		key.to_s(16)
	Qt::ToolTip::showText(event.globalPos, text, self)
      end

      def mousePressEvent event
	if event.button == Qt::LeftButton
	  @lastKey = (event.y / @squareSize) * @columns + event.x / @squareSize
	  ch = Qt::Char.new(@lastKey)
	  unless ch.category == Qt::Char::NoCategory
	    text = ''
	    text.force_encoding 'utf-8'
	    text << @lastKey
  #           tag "emit characterSelected(text:encoding=#{text.encoding})"
  #           emit characterSelected(text)
	    characterSelected text
	  end
	  update
	else
	  super
	end
      end

      def paintEvent event
	painter = Qt::Painter.new(self)
	painter.fillRect(event.rect, Qt::Brush.new(Qt::white));
	painter.setFont(@displayFont);
	redrawRect = event.rect;
	beginRow = redrawRect.top/@squareSize;
	endRow = redrawRect.bottom/@squareSize;
	beginColumn = redrawRect.left/@squareSize;
	endColumn = redrawRect.right/@squareSize;
	painter.setPen(Qt::Pen.new(Qt::gray));
	(beginRow..endRow).each do |row|
	  (beginColumn..endColumn).each do |column|
	    painter.drawRect(column*@squareSize, row*@squareSize, @squareSize, @squareSize);
	  end
	end

	fontMetrics = Qt::FontMetrics.new(@displayFont);
	painter.setPen(Qt::Pen.new(Qt::black));
	(beginRow..endRow).each do |row|
	  (beginColumn..endColumn).each do |column|
	    key = row*@columns + column;
	    painter.setClipRect(column*@squareSize, row*@squareSize, @squareSize, @squareSize);

	    if (key == @lastKey)
	      painter.fillRect(column*@squareSize + 1, row*@squareSize + 1, @squareSize, @squareSize,
			       Qt::Brush.new(Qt::red));
	    end

	    painter.drawText(column*@squareSize + (@squareSize / 2) -
			     fontMetrics.width(Qt::Char.new(key))/2,
			     row*@squareSize + 4 + fontMetrics.ascent,
			     Qt::Char.new(key).to_s);
	  end
	end
      end # def paintEvent

      slots 'updateFont(QFont)', 'updateSize(QString)', 'updateStyle(QString)',
	    'updateFontMerging(bool)'

      signals 'characterSelected(QString)'

      def displayFont= font
	#tag "displayFont=#{font}"
	@displayFont = font
	@squareSize = [24, Qt::FontMetrics.new(@displayFont).xHeight * 3].max
	adjustSize
	update
      end
     
  end # class QCharacterWidget

  class CharacterWidget < Widget
    private
      def whenCharacterSelected &block
	connect(@qtc, SIGNAL('characterSelected(QString)'), self) do |ch| 
	  rfCallBlockBack(ch, &block)
	end
      end

      # override
      def applyModel data
#	tag "applyModel(#{data})"
	@qtc.displayFont = data
      end
    protected

#      def whenConnected model = nil, propagation = nil, &block
#	tag "whenConnected"
#	@qtc.displayFont = model unless block
#	super
#      end
  end # class CharacterWidget

  createInstantiator File.basename(__FILE__, '.rb'), QCharacterWidget, CharacterWidget

end  # module Reform
