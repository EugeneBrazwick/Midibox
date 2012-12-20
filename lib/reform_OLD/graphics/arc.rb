# Copyright (c) 2011 Eugene Brazwick

module Reform

  require_relative 'rfellipse'

=begin

  Arcs do not look too good with the default pen. Make sure use use cap :flat.
=end
  ArcItem = ReformEllipse

  class QArcItem < QReformEllipseItem
    private
      def drawEllipsePart painter, rect, from, to
        painter.drawArc rect, from, to
        painter.pen = Qt::Pen.new(Qt::NoPen)
        painter.drawPie rect, from, to
      end
  end

  createInstantiator File.basename(__FILE__, '.rb'), QArcItem, ArcItem
end
