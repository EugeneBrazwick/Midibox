=begin

NOTE from Eugene.
There seem to be SEVER problems with Qt.
When pieview has no model yet and you resize it beyond 800 pixels wide or so
# resizeEvents keep coming forever.


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

require 'reform/abstractitemview'

module Reform

  class PieView < AbstractItemView
    extend Forwardable
    private
      def initialize parent, qtc
        super
        column
        column
      end

      def col0
        @col0 ||= col(0)
      end

      def col1
        @col1 ||= col(1)
      end

      def_delegators :col0, :decorator, :itemkey, :display_connector, :display,
                            :local_connector, :decoration, :itemdecoration,
                            :key_connector

      def_delegator :col1, :local_connector, :value_connector

  end # class PieView

  class QPieView < Qt::AbstractItemView
    include QWidgetHackContext

    private
      def initialize qparent
        super
        @margin = 8;
        @totalSize = 300;
        @pieSize = @totalSize - 2 * @margin;
        @validItems = 0;
        @totalValue = 0.0;
        @origin = Qt::Point.new
        @rubberBand = nil
#         @nevermind_the_geo = false
        horizontalScrollBar().setRange(0, 0);
        verticalScrollBar().setRange(0, 0);
        setVerticalScrollBarPolicy(Qt::ScrollBarAlwaysOff);
        setHorizontalScrollBarPolicy(Qt::ScrollBarAlwaysOff);
        # the next line helps againt the resize flood.
        # with 'setMinimumSize' we get a paint flood instead....
        # TRIAL AND ERROR CODE ALERT!!!
        viewport.resize(2600, 2600)
      end

=begin /*
     Returns the rectangle of the item at position \a index in the
     model. The rectangle is in contents coordinates.
 */
=end

      def itemRect(index)
#         tag "itemRect"
        return Qt::Rect.new unless index.valid?

      #// Check whether the index's row is in the list of rows represented
      # // by slices.

=begin

Eugene: this pieview only shows how it NOT works....

This does not use an abstract model.
It clearly assumes that column 1 contains the relative slicesize.

And column 0 contains the labels + the color (deco-role)
=end
        if (index.column() != 1)
          valueIndex = model().index(index.row(), 1, rootIndex());
        else
          valueIndex = index;
        end
#         tag "itemRect. valueIndex = #{valueIndex}"
        if (model().data(valueIndex).toDouble() > 0.0)
          listItem = 0;
          row = index.row() - 1;
          while row >= 0
            if (model().data(model().index(row, 1, rootIndex())).toDouble() > 0.0)
              listItem += 1;
            end
            row -= 1
          end

          case index.column()
          when 0
            itemHeight = Qt::FontMetrics.new(viewOptions().font).height();
            return Qt::Rect.new(@totalSize,
                                (@margin + listItem * itemHeight).to_i,
                                @totalSize - @margin, itemHeight.to_i);
          when 1
            return viewport().rect();
          end
        end
        return Qt::Rect.new();
      end

      def itemRegion index
#         tag "itemRegion"
        return Qt::Region.new unless index.valid?
        return itemRect(index) unless index.column() == 1
        return Qt::Region.new if (model().data(index).toDouble() <= 0.0)
        startAngle = 0.0;
        row = 0;
        n = model().rowCount(rootIndex())
        tag "rowCount -> #{n}"
        for row in 0...n
          sliceIndex = model().index(row, 1, rootIndex());
          value = model().data(sliceIndex).toDouble();
          next unless value > 0.0
          angle = 360 * value / @totalValue;
          if (sliceIndex == index)
            slicePath = Qt::PainterPath.new
            slicePath.moveTo(@totalSize / 2, @totalSize / 2);
            slicePath.arcTo(@margin, @margin, @margin + @pieSize, @margin + @pieSize,
                            startAngle, angle);
            slicePath.closeSubpath();
            return Qt::Region.new(slicePath.toFillPolygon().toPolygon());
          end
          startAngle += angle;
        end
        return Qt::Region.new();
      end

      def rows(index)
        model().rowCount(model().parent(index)).tap{|r|tag "rows->#{r}"}
      end

      def updateGeometries()
        return unless model
#         tag "updateGeometries"
#         return if @nevermind_the_geo
#         @nevermind_the_geo = true

#         STDERR.puts "FIXME, QPieView::updateGeometries: BROKEN"
#         return
=begin
        # FIXME: this called from resizeEvent, and it causes them too. So it causes a 100% CPU load.
 pieview.rb:135:in `updateGeometries' updateGeometries, totalSize = 300, viewport = 833x238
pieview.rb:305:in `resizeEvent' resizeEvent
pieview.rb:135:in `updateGeometries' updateGeometries, totalSize = 300, viewport = 502x503
pieview.rb:305:in `resizeEvent' resizeEvent
pieview.rb:135:in `updateGeometries' updateGeometries, totalSize = 300, viewport = 518x503
pieview.rb:305:in `resizeEvent' resizeEvent
pieview.rb:135:in `updateGeometries' updateGeometries, totalSize = 300, viewport = 833x238
pieview.rb:305:in `resizeEvent' resizeEvent
pieview.rb:135:in `updateGeometries' updateGeometries, totalSize = 300, viewport = 502x503
pieview.rb:305:in `resizeEvent' resizeEvent
pieview.rb:135:in `updateGeometries' updateGeometries, totalSize = 300, viewport = 518x503

Of course, there was no pie yet, so could that influence the control?
Anyway this is a major problem since the control may be left uninitialized.

totalsize is normally a constant
=end
#         tag "updateGeometries, totalSize = #@totalSize, viewport = #{viewport.width}x#{viewport.height}"
        vw, vh = viewport.width, viewport.height
        # Qt example
        horizontalScrollBar.pageStep = vw
        verticalScrollBar.pageStep = vh
          # why is 2*??? estimate: required area is w=2*totalsize, h=totalsize

=begin
# FIXME: this looks OK but causes immediate 100% CPULOAD
# then, if left out it looks more OK, until you resize the control beyond about 800 pixels wide.
# then it behaves chaotic:
pieview.rb:348:in `resizeEvent' resizeEvent, sz = 1184x231
pieview.rb:141:in `updateGeometries' updateGeometries, nevermind_the_geo = false
pieview.rb:166:in `updateGeometries' updateGeometries, totalSize = 300, viewport = 1184x231
qt4 is BROKEN, resizeEvents keep being sent forever!!
pieview.rb:348:in `resizeEvent' resizeEvent, sz = 838x488
pieview.rb:141:in `updateGeometries' updateGeometries, nevermind_the_geo = false
pieview.rb:166:in `updateGeometries' updateGeometries, totalSize = 300, viewport = 838x488
pieview.rb:271:in `paintEvent' paintEvent
qt4 is BROKEN, resizeEvents keep being sent forever!!
pieview.rb:348:in `resizeEvent' resizeEvent, sz = 1184x231

It loops between 1184x231 <-> 838x488
=end

         horizontalScrollBar().setRange(0, [0, 2 * @totalSize - vw].max);
         verticalScrollBar().setRange(0, [0, @totalSize - vh].max);



# Qt example says:
         wsz = size
         horizontalScrollBar.setRange(0, [0, wsz.width - vw].max);
         verticalScrollBar.setRange(0, [0, wsz.height - vh].max);
#         updateWidgetPosition # not original  ??
# AND IT STILL CAUSES A CPULOAD OF 100%
# ????
      end

      def rescanModel
        @validItems = 0;
        @totalValue = 0.0;
        row = 0;
        n = model().rowCount(rootIndex());
        for row in 0...n
          index = model().index(row, 1, rootIndex());
          value = model().data(index).toDouble();
          if value > 0.0
            @totalValue += value;
            @validItems += 1;
          end
       end
#         tag "dataChanged, repaint"
        viewport().update();
      end

    public

      # override
      def dataChanged(topLeft, bottomRight)
#         tag "dataChanged"
        super
        rescanModel
      end

# incompatible with pieview_rd
#       def setModel qmodel
#         super
#         rescanModel
#       end

#       def model= qmodel
#         super
#         rescanModel
#       end

      # override
      def edit(index, trigger, event)
#         tag "edit"
        if (index.column() == 0)
          super
        else
          false;
        end
      end

      # override
      def isIndexHidden(*)
        false;
      end

      # override
      def horizontalOffset()
#         tag "horizontalOffset"
        model ? horizontalScrollBar().value() : 0;
      end

      # override
      def mousePressEvent event
        super
        @origin = event.pos();
        @rubberBand ||= Qt::RubberBand.new(Qt::RubberBand::Rectangle, viewport());
        @rubberBand.setGeometry(Qt::Rect.new(@origin, Qt::Size.new()));
        @rubberBand.show();
      end

      # override
      def mouseMoveEvent(event)
        if (@rubberBand)
          @rubberBand.setGeometry(Qt::Rect.new(@origin, event.pos()).normalized());
        end
        super
      end

      # override
      def mouseReleaseEvent(event)
        super
        if (@rubberBand)
         @rubberBand.hide();
        end
#         tag "mouseReleaseEvent, repaint"
        viewport().update();
      end

      # override
      def moveCursor(cursorAction, *)
#         tag "moveCursor"
        current = currentIndex();
        case cursorAction
        when MoveLeft, MoveUp
          if (current.row() > 0)
            current = model().index(current.row() - 1, current.column(), rootIndex());
          else
            current = model().index(0, current.column(), rootIndex());
          end
        when MoveRight, MoveDown
          if (current.row() < rows(current) - 1)
            current = model().index(current.row() + 1, current.column(), rootIndex());
          else
            current = model().index(rows(current) - 1, current.column(), rootIndex());
          end
        end
#         tag "moveCursor, repaint"
        viewport().update();
        current;
      end

      # override
      def paintEvent(event)
#         tag "paintEvent, qmodel = #{model}"
        return super  unless model  # fixes it partly??
        selections = selectionModel();
        option = viewOptions();
        state = option.state;
        background = option.palette.base();
        foreground = Qt::Pen.new(option.palette.color(Qt::Palette::WindowText));
        textPen = Qt::Pen.new(option.palette.color(Qt::Palette::Text));
        highlightedPen = Qt::Pen.new(option.palette.color(Qt::Palette::HighlightedText));
        painter = Qt::Painter.new(viewport());
        begin
          painter.setRenderHint(Qt::Painter::Antialiasing);
          painter.fillRect(event.rect(), background);
          painter.setPen(foreground);
#      // Viewport rectangles
          pieRect = Qt::Rect.new(@margin, @margin, @pieSize, @pieSize);
          keyPoint = Qt::Point.new(@totalSize - horizontalScrollBar().value(),
                                   @margin - verticalScrollBar().value());
          if @validItems > 0
            painter.save();
            painter.translate(pieRect.x() - horizontalScrollBar().value(),
                              pieRect.y() - verticalScrollBar().value());
            painter.drawEllipse(0, 0, @pieSize, @pieSize);
            startAngle = 0.0;
            row = 0
            n = model().rowCount(rootIndex())
            while row < n

              index = model().index(row, 1, rootIndex());
              value = model().data(index).toDouble();

              if (value > 0.0)
                angle = 360 * value / @totalValue;

                colorIndex = model().index(row, 0, rootIndex());
                color = Qt::Color.new(model().data(colorIndex, Qt::DecorationRole).toString());
                if (currentIndex() == index)
                  painter.setBrush(Qt::Brush.new(color, Qt::Dense4Pattern));
                elsif (selections.isSelected(index))
                  painter.setBrush(Qt::Brush.new(color, Qt::Dense3Pattern));
                else
                  painter.setBrush(Qt::Brush.new(color));
                end
                painter.drawPie(0, 0, @pieSize, @pieSize, (startAngle * 16).to_i, (angle * 16).to_i);
                startAngle += angle;
              end
              row += 1
            end
            painter.restore();

            keyNumber = 0;

            for row in 0...n
              index = model().index(row, 1, rootIndex());
              value = model().data(index).toDouble();

              next unless value > 0.0
              labelIndex = model().index(row, 0, rootIndex());

              option = viewOptions();
              option.rect = visualRect(labelIndex);
              if (selections.isSelected(labelIndex))
                option.state |= Qt::Style::State_Selected;
              end
              if (currentIndex() == labelIndex)
                option.state |= Qt::Style::State_HasFocus;
              end
              itemDelegate().paint(painter, option, labelIndex);
              keyNumber += 1
            end
          end
        ensure
          painter.end
        end
      end #  def paintEvent

      # override
      def resizeEvent(event)
#         STDERR.puts "qt4 is BROKEN, resizeEvents keep being sent forever!!"
#         tag "#{self}::resizeEvent, sz = #{event.size.width}x#{event.size.height}, oldsize=#{event.oldSize.inspect}, event=#{event.inspect}, event.spontaneous=#{event.spontaneous}"
#         tag "size = #{size.inspect}, parent.size = #{parent.size.inspect}, parent =  #{parent}, splittersize =#{parent.sizes.inspect}"
#         tag "viewport = #{viewport}, vpsize = #{viewport.size.inspect}"
#         event.ignore if parent.size.width - event.size.width < 24
        updateGeometries();           #CAUSES a new resizeEvent... No, in itself is it broken already FIXME
        super
      end

      # override
      def rowsInserted(parent, start, e_nd)
        for row in start..e_nd
          index = model().index(row, 1, rootIndex());
          value = model().data(index).toDouble();
          if (value > 0.0)
            @totalValue += value;
            @validItems += 1
          end
        end
        super
      end

       #override
      def rowsAboutToBeRemoved(parent, start, e_nd)
        for row in start..e_nd
          index = model().index(row, 1, rootIndex());
          value = model().data(index).toDouble();
          if (value > 0.0)
            @totalValue -= value;
            @validItems -= 1
          end
        end
        super
      end

      # override
      def scrollContentsBy(dx, dy)
#         tag "scrollContentsBy"
        viewport().scroll(dx, dy);
      end

=begin  override
 /*
     Find the indices corresponding to the extent of the selection.
 */
=end
      def setSelection(rect, command)
#         tag "setSelection"
#     // Use content widget coordinates because we will use the itemRegion()
#      // function to check for intersections.
        contentsRect = rect.translated(horizontalScrollBar().value(), verticalScrollBar().value()).normalized();
        rows = model().rowCount(rootIndex());
        columns = model().columnCount(rootIndex());
        indexes = []
        for row in 0...rows
          for column in 0...columns
            index = model().index(row, column, rootIndex());
            region = itemRegion(index);
            unless region.intersect(contentsRect).isEmpty()
              indexes << index
            end
          end
        end
        unless indexes.empty?
          firstRow = indexes[0].row();
          lastRow = indexes[0].row();
          firstColumn = indexes[0].column();
          lastColumn = indexes[0].column();

# ALAS          index.each_with_index do |idx, i|
#             next if i == 0
#             firstRow = [firstRow, idx.row()].min;
#             lastRow = [lastRow, idx.row()].max;
#             firstColumn = [firstColumn, idx.column()].min;
#             lastColumn = [lastColumn, idx.column()].max
#           end
          n = indexes.length
          for i in 1...n do
            firstRow = [firstRow, indexes[i].row].min
            lastRow = [lastRow, indexes[i].row].max
            firstColumn = [firstColumn, indexes[i].column].min
            lastColumn = [lastColumn, indexes[i].column].max
          end

          if firstRow <= lastRow && firstColumn <= lastColumn
            tag "select(#{firstRow},#{firstColumn} upto #{lastRow}, #{lastColumn})"
            selection = Qt::ItemSelection.new(
              model().index(firstRow, firstColumn, rootIndex()),
              model().index(lastRow, lastColumn, rootIndex()));
            selectionModel().select(selection, command)  # SEGV
          end
        else
          noIndex = Qt::ModelIndex.new
          selection = Qt::ItemSelection.new(noIndex, noIndex);
          selectionModel().select(selection, command) # if selection.valid?
        end
#         tag "setSelection, repaint"
        viewport.update();  # Eugene: was just 'update'
      end

      # override
      def verticalOffset
#         tag "verticalOffset"
        model ? verticalScrollBar().value() : 0;
      end

=begin  override
 /*
     Returns a region corresponding to the selection in viewport coordinates.
 */
=end
      def visualRegionForSelection(selection)
#         tag "visualRegionForSelection"
        ranges = selection.count();
        return Qt::Rect.new if (ranges == 0)
        region = Qt::Region.new
        for i in 0...ranges
          range = selection.at(i);
          for row in range.top()..range.bottom()
            for col in range.left()..range.right()
              index = model().index(row, col, rootIndex());
              region += visualRect(index);
            end
          end
        end
        region
      end

=begin
 /*
     Returns the position of the item in viewport coordinates.
 */
=end
      def visualRect(index)
#         tag "visualRect"
        rect = itemRect(index);
        if (rect.isValid())
          return Qt::Rect.new(rect.left() - horizontalScrollBar().value(),
                              rect.top() - verticalScrollBar().value(),
                              rect.width(), rect.height());
        end
        rect;
      end

      def scrollTo(index, *)
#         tag "scrollTo"
        area = viewport().rect();
        rect = visualRect(index);
        if (rect.left() < area.left())
          horizontalScrollBar().setValue(horizontalScrollBar().value() + rect.left() - area.left());
        elsif (rect.right() > area.right())
          horizontalScrollBar().setValue(horizontalScrollBar().value() +
                                         [rect.right() - area.right(), rect.left() - area.left()].min);
        end
        if (rect.top() < area.top())
          verticalScrollBar().setValue(verticalScrollBar().value() + rect.top() - area.top());
        elsif (rect.bottom() > area.bottom())
          verticalScrollBar().setValue(verticalScrollBar().value() +
                                       [rect.bottom() - area.bottom(), rect.top() - area.top()].min);
        end
#         tag "scrollTo, repaint"
        update();
      end

=begin
 /*
     Returns the item that covers the coordinate given in the view.
 */
=end

      def indexAt(point)
#         tag "indexAt"
        return Qt::ModelIndex.new if (@validItems == 0)

#      // Transform the view coordinates into contents widget coordinates.
        wx = point.x() + horizontalScrollBar().value();
        wy = point.y() + verticalScrollBar().value();

        if (wx < @totalSize)
          cx = wx - @totalSize / 2;
          cy = @totalSize / 2 - wy; #// positive cy for items above the center

#          // Determine the distance from the center point of the pie chart.
          d = (cx * cx + cy * cy) ** 0.5
          if (d == 0 || d > @pieSize / 2)
            return Qt::ModelIndex.new();
          end

#          // Determine the angle of the point.
          angle = (180 / Math::PI) * Math::acos(cx / d);
          if (cy < 0)
            angle = 360 - angle;
          end
#          // Find the relevant slice of the pie.
          startAngle = 0.0;

          row = 0
          n = model().rowCount(rootIndex())
          for row in 0...n
            index = model().index(row, 1, rootIndex());
            value = model().data(index).toDouble();

            if (value > 0.0)
              sliceAngle = 360 * value / @totalValue;

              if (angle >= startAngle && angle < (startAngle + sliceAngle))
                return model().index(row, 1, rootIndex());
              end
              startAngle += sliceAngle;
            end
          end
        else
          itemHeight = Qt::FontMetrics.new(viewOptions().font).height();
          listItem = ((wy - @margin) / itemHeight).to_i;
          validRow = 0;
          row = 0
          n = model().rowCount(rootIndex())
          for row in 0...n
            index = model().index(row, 1, rootIndex());
            if (model().data(index).toDouble() > 0.0)
              if (listItem == validRow)
                return model().index(row, 0, rootIndex());
              end

#               // Update the list index that corresponds to the next valid row.
              validRow += 1
            end
          end
        end
        Qt::ModelIndex.new();
      end

  end

  createInstantiator File.basename(__FILE__, '.rb'), QPieView, PieView
end