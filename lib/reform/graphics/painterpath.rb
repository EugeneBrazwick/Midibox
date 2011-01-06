
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
      qt_implementor_class.new   # ignore parent again (but why???)
    end

    def addTo parent, hash, &block
      parent.addGraphicsItem @qtc.toFillPolygon, hash, &block
    end

    # the block is passed two arguments, the element and if a curve
    # the element info.
    # Unfortunately we cannot use it to make alterations, since
    # the internal structure of the curve-info is unknown, nor is
    # there a way to replay the curve-elements on another painterpath.
    # Note that for straight lines such replay is very well possible.
    def each &block
      return to_enum unless block
      i, n = 0, @qtc.elementCount
      while i < n
        el = @qtc.elementAt(i)
        if el.curveTo?
          i += 1
          info = @qtc.elementAt(i)
          yield el, info
        else
          yield el, nil
        end
        i += 1
      end
    end

    alias :each_element :each

#     def self.contextsToUse
#       GraphicContext
#     end


  end # PainterPath

  createInstantiator File.basename(__FILE__, '.rb'), Qt::PainterPath, PainterPath

end # Reform