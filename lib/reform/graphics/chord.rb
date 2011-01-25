# Copyright (c) 2011 Eugene Brazwick

module Reform

  require_relative 'rfellipse'

  ChordItem = ReformEllipse

  class QChordItem < QReformEllipseItem
    private
      def drawEllipsePart painter, rect, from, to
        painter.drawChord rect, from, to
      end
  end

  createInstantiator File.basename(__FILE__, '.rb'), QChordItem, ChordItem
end
