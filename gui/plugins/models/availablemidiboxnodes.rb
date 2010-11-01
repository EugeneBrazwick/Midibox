
require 'midibox/midiboxnode'

# This is simplistic ad-hoc model that enumerates the available nodes
# We should store nodes in the config file too, and the merge the
# truly detected ones.
# Ah well....
class AvailableNodes < Reform::Structure
  private
    def initialize *args
      super
      @value = []
      Dir[File.dirname(__FILE__) + '/../nodes/*'].each do |file|
        load file
      end
#       tag "calling nodes"
      Midibox::Node::nodes.each do |klass|
        # one would think that klass itself would be best but it cannot be yaml'ed...
#         tag "Assigning hash as next element in array @value, should be interred automagically"
        self << { iconpath: klass.iconpath, classname: klass.name } # , mimeType: 'text/midiboxnode' }
      end
    end

  public

    def mimeType
#       tag "mimeType, invent something texty"
      'text/midiboxnode'
    end
end

Reform::createInstantiator File.basename(__FILE__, '.rb'), nil, AvailableNodes
