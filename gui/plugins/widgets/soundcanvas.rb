
require 'reform/widgets/canvas'
require 'midibox/midiboxnode'
require 'midibox/command'
require 'midibox/theme'

# a Canvas is a frame that can contain graphic items like 'circle' etc.
class SoundCanvas < Reform::Canvas
  private

    def initialize p, qp
      super
      backgroundBrush $theme.yellow
#       tag "#@qtc::acceptDrops := true"
      @qtc.acceptDrops = true
      # make sure strange movements do not occur when adding items
      @qtc.setSceneRect(0.0, 0.0, 1000.0, 1000.0)
    end

  public
    # the pos passed is the scene position.
    def dropNode klass, qscenepos
      item = klass.new(self, klass.qclass.new)
#       tag "dropNode, qscenepos=#{qscenepos.inspect}"
      cmd = Midibox::AddNodeCommand.new(scene, item, qscenepos)
#       tag "undo = #$undo"
#       tag "undo.activeStack = #{$undo.activeStack}"
      $undo.push(cmd)
    end
end # class SoundCanvas

=begin IMPORTANT
the drag drop code must be made generic.
That should be relatively easy.
=end
class QSoundCanvas < Reform::QGraphicsView
  public
    AcceptedMimeType = 'text/midiboxnode'

    def dragEnterEvent event
#       tag "dragEnterEvent(#{event}), mimedata = #{event.mimeData.inspect}, formats=#{event.mimeData.formats.inspect}"
      rfRescue do
        if event.mimeData.hasFormat(AcceptedMimeType)
  #         tag "acceptProposedAction!!!"
          event.acceptProposedAction
        else
  #         tag "text/midiboxnode not available!!"
          event.ignore
        end
      end
    end

    def dragMoveEvent event
      rfRescue do
        return event.ignore unless (event.dropAction & Qt::CopyAction) != 0
#       tag "dragMove, pos=#{event.pos.inspect}"
        event.accept
      end
    end

    def dropEvent event
#       tag "dropEvent(#{event})"
      rfRescue do
        return event.ignore unless (event.dropAction & Qt::CopyAction) != 0
        require 'stringio'
  #       tag "event.mimeData = #{event.mimeData.inspect}"
        data = event.mimeData.data(AcceptedMimeType)
  #       tag "got data: #{data}" # a QByteArray
        datastream = Qt::DataStream.new(data, Qt::IODevice::ReadOnly)
  #       yamltext = ''
  #       yamltext_ohmygod = Qt::Variant.new(yamltext)
        yamltext_ohmygod = ''
        datastream >> yamltext_ohmygod
  #       tag "got yamltext '#{yamltext_ohmygod}'"
        io = StringIO.new(yamltext_ohmygod)
        require 'yaml'
        YAML::parse_documents(io) do |yaml_basenode|
  #         tag "yaml_basenode = #{yaml_basenode}"
          nodeinfo = yaml_basenode.transform
  #         tag "node = #{node}"
  #         tag "Accepting hash #{node.inspect}, at pos #{event.pos.inspect}"
          @_reform_hack.dropNode(Kernel::const_get(nodeinfo[:classname]), mapToScene(event.pos.x, event.pos.y))
          break # ignore other parts of the selection
        end
        event.acceptProposedAction
      end
    end

end

Reform::createInstantiator(File.basename(__FILE__, '.rb'), QSoundCanvas, SoundCanvas)
