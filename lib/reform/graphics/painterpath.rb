
module Reform

  require_relative '../control'
  require 'forwardable'

  # ALERT: this pushes it to the limit. a Qt::PainterPath is NOT a Qt::GraphicItem at all!
  class PainterPath < Control
    extend Forwardable
  private
    def initialize parent = nil, qtc = nil, &block
      qtc = Qt::PainterPath.new unless qtc
      super(parent, qtc) {}
#       tag "Calling instance_eval on block, self = #{self}, qtc=#@qtc"
      self.instance_eval(&block) if block
    end

    # arcTo,  first the bounding rectangle, topleft, wxh. Then the startangle (up == 0, ccw).
    # finally the sweepangle (ccw).  The starting point is always the center.
    def_delegators :@qtc, :lineTo, :moveTo, :arcTo, :closeSubpath, :cubicTo, :fillRule=

    # ugly stuff:
    def_delegators :@qtc, :addText

#     def moveTo x, y
#       @qtc.moveTo x, y
#     end

    alias :close :closeSubpath

  public

    def self.new_qt_implementor qt_implementor_class, parent, qt_parent
      qt_implementor_class.new
    end

    def addTo parent, hash, &block
      parent.addGraphicsItem @qtc.toFillPolygon, hash, &block
    end

    def self.contextsToUse
      GraphicContext
    end


  end # PainterPath

  createInstantiator File.basename(__FILE__, '.rb'), Qt::PainterPath, PainterPath

end # Reform