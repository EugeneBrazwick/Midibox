

require 'Qt'
require_relative 'draglabel'

module Reform

  class QDragWidget < QWidget
    private
      def initialize parent = nil
#         tag "PARENT???"
        if parent
#           tag "CALLING QWidget.new(#{parent})"
          super(parent)
        else
#           tag "CALLING QWidget.new()"
          super()
        end
#         tag "HERE"
        x = y = 5
        %w[ Colorless green ideas sleep furiously A colorless green idea is a new untried
            idea that is  without vividness dull and unexciting To sleep furiously may
            seem a puzzling turn of phrase but the mind in sleep often indeed moves
            furiously with ideas and images flickering in and out].each do |word|
          wordLabel = QDragLabel.new(self, word);
          wordLabel.move(x, y);
          wordLabel.show();
          wordLabel.setAttribute(Qt::WA_DeleteOnClose);
          x += wordLabel.width() + 2;
          if (x >= 245)
            x = 5;
            y += wordLabel.height() + 2;
          end
        end
        setMinimumSize(400, [200, y].max);
        setWindowTitle(tr("Fridge Magnets"));
        setAcceptDrops(true);
      end

    protected
      def dragEnterEvent(event)
        if (event.mimeData().hasFormat("application/x-fridgemagnet"))
          if (children().include?(event.source()))
            event.setDropAction(Qt::MoveAction);
            event.accept();
          else
            event.acceptProposedAction();
          end
        elsif (event.mimeData().hasText())
          event.acceptProposedAction();
        else
          event.ignore();
        end
      end

      def dragMoveEvent(event)
        if (event.mimeData().hasFormat("application/x-fridgemagnet"))
          if (children().include?(event.source()))
            event.setDropAction(Qt::MoveAction);
            event.accept();
          else
            event.acceptProposedAction();
          end
        elsif (event.mimeData().hasText())
          event.acceptProposedAction();
        else
          event.ignore();
        end
      end

      def dropEvent(event)
        if (event.mimeData().hasFormat("application/x-fridgemagnet"))
#           tag "got x-fridgemagnet"            OK works
          mime = event.mimeData();
          itemData = mime.data("application/x-fridgemagnet");
          dataStream = Qt::DataStream.new(itemData, Qt::IODevice::ReadOnly);
          text = ''
          offset = Qt::Point.new
          dataStream >> text >> offset;
          newLabel = QDragLabel.new(self, text);
          newLabel.move(event.pos() - offset);
          newLabel.show();
          newLabel.setAttribute(Qt::WA_DeleteOnClose);

          if (event.source() == self)
            event.setDropAction(Qt::MoveAction);
            event.accept();
          else
            event.acceptProposedAction();
          end
        elsif (event.mimeData().hasText())
          pieces = event.mimeData().text().split(/\\s+/)
          position = event.pos();

          pieces.each do |piece|
            next if piece.empty?
            newLabel = QDragLabel.new(self, piece);
            newLabel.move(position);
            newLabel.show();
            newLabel.setAttribute(Qt::WA_DeleteOnClose);
            position += Qt::Point.new(newLabel.width(), 0);
          end

          event.acceptProposedAction();
        else
          event.ignore();
        end
      end

      def mousePressEvent(event)
        child = childAt(event.pos()) or return
        hotSpot = event.pos() - child.pos();

        itemData = Qt::ByteArray.new
        dataStream = Qt::DataStream.new(itemData, Qt::IODevice::WriteOnly);
        dataStream << child.text() << Qt::Point.new(hotSpot);

        mimeData = Qt::MimeData.new
        mimeData.setData("application/x-fridgemagnet", itemData);
        mimeData.setText(child.text());

        drag = Qt::Drag.new(self);
        drag.setMimeData(mimeData);
        drag.setPixmap(child.pixmap());
        drag.setHotSpot(hotSpot);

        child.hide();

        if (drag.exec(Qt::MoveAction | Qt::CopyAction, Qt::CopyAction) == Qt::MoveAction)
          child.close();
        else
          child.show();
        end
      end
  end

  createInstantiator File.basename(__FILE__, '.rb'), QDragWidget #DragWidget

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

