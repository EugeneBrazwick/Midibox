
module Midibox

  require 'reform/undo'

#   $errrrm = Qt::UndoCommand.new('errrrm')

  class AddNodeCommand < Reform::QUndoCommand
    private
      def initialize scene, item, pos
        super($qApp.tr('add node'))
        @qscene, @item, @pos = scene, item, pos
#         tag "AddNodeCommand.new, pos = #{@pos.inspect}"
      end

    public
      def redo
        @qscene.addItem(i = @item.qtc)
        i.pos = @pos # i.mapFromScene(@scenepos).tap{|n|tag "i.pos:=#{n.inspect}, but scenepos=#{@scenepos.inspect}"}
      end

      def undo
        qtc = @item.qtc
        qtc.clearFocus
        @qscene.removeItem(qtc)
        qtc.update
#        @item.deleteLater              NO!
      end
  end

  class AlterNodeStateCommand < Reform::QUndoCommand
    private
      def initialize node, statehash
        super($qApp.tr('change nodestate'))
        @node, @statehash = node, statehash
        @orgstate = node.state
      end

      def realize_state state
        @node.state = state
      end

    public

      attr :statehash, :node

      def redo
        realize_state @statehash
      end

      def undo
        realize_state @orgstate
      end
  end # class AlterNodeStateCommand

  class NodeCommand < Reform::QUndoCommand
    private
      def initialize text, node
        super(text)
        @node = node
      end
    public
      attr :node
  end

  class ResizeNodeCommand < NodeCommand
    private
      def initialize node, neww, newh, orgw, orgh
        super($qApp.tr('resize node'), node)
        @w, @h = neww, newh
        @orgw, @orgh = orgw, orgh # node.width, node.height
      end

    public

      attr :w, :h

      def redo
        @node.resize(@w, @h)
      end

      def undo
        @node.resize(@orgw, @orgh)
      end
  end # class ResizeNodeCommand

  class MoveNodeCommand < NodeCommand
    private
      def initialize node, newpos, orgpos
        super($qApp.tr('move node'), node)
        @newpos, @orgpos = newpos, orgpos  # QPointF
      end

      def activatePos pos
        tag "MoveNodeCommand::activatePos #{pos.inspect}"
        # prevent itemChange trigger....
        qtc = @node.qtc
        flags = qtc.flags
        begin
          qtc.setFlag(Qt::GraphicsItem::ItemSendsGeometryChanges, false)
          qtc.setFlag(Qt::GraphicsItem::ItemSendsScenePositionChanges, false)
          qtc.pos = pos
        ensure
          qtc.setFlags(flags)
        end
      end

    public
      def redo
        return if @node.qtc.pos == @newpos
        activatePos @newpos
      end

      def undo
        @orgpos and
          activatePos @orgpos
      end
  end
end # module Midibox
