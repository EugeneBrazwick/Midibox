
require 'midibox/midiboxnode.rb'

ImageDir = File.dirname(__FILE__) + '/../../images/'

class AlsaPortNode < Midibox::Node
  public
    def self.iconpath
      'file://' + ImageDir + #'alsaport.svg.gz'
        'keyboard_in.svg'  # BOGO quality . Inkscape is far too slow
    end
end

Reform::createInstantiator(File.basename(__FILE__, '.rb'), AlsaPortNode::qclass, AlsaPortNode)
