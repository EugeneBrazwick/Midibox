
require 'midibox/midiboxnode.rb'

ImageDir = File.dirname(__FILE__) + '/../../images/'

=begin
this is an input or output node.

The controls are
  1 - Combo , portname (including client).
  2a - Brand. Combo
  2b - Device, the type of device, Like 'E-80'. Combo.  Brand + Device automatically form the title.

  3 - queueoperator control.  Pause, run, rewind, forward, Record, Play.
      Midi IN only has record, pause, resume and stop, and erase (?)
      Midi OUT has play, pause, resume, and stop.

      > < || >> << O X

The connections are:
  output - (or input), kind 'chunk' probably. A single orange circle (img) on the right,
           for Midi OUT, or a blue on on the left (for Midi IN).

  queuecontrol - connects the position of playing and probably recording as well.
                 it should connect to the song-bar.
  both in and out. If 'in' is set, the control vanishes.

  text in - for brand + device. Features, features. Any value has an input
  connector. If connected the control vanishes.


1) Normal sequencers have a central queuecontrol. This makes sense since the user
will have a hard time clicking on record on one node, and on play on another.
However, we allow the queues to be connected.

2) 'erase' makes no sense. Since the node is only a source or sink for midi events.
There is no storage.

3) Brand + device are normally the same if we connect to the same port. So it makes
sense that the application remembers the last one present, and saves these to the
global config.

4) What should 'play' do if there is nothing connected.

5) queuecontrol messages can be passed by track too. Do we need a special connector?
When we connect the track and if the queueconnections are unoccupied, connect these
implicitely ? In general you don't need this signal as recording is normally
done part by part and by using devices as pedals. We need a count-in or an
option to start the recording when the first event arrives. Set the position you
want to record (overwrite), pick the track and start playing.  Much easier than
any count-in.  But then, you should get the tempo right immediately...

==========================================================================
Some setups
==========================================================================

A) aconnect.  By connecting two midiports you create an alsaconnection that is visible elsewhere too.
              Also, if two ports are present (at least) then the program must respond to connections made
              and deleted.  It would be nice if the connectorlayout of the last connection between
              device A and B would be persistent over sessions. As long as components are
              not moved, that is.

B) arecordmidi. We need storage. That would be the songbar. Also sinks like a file-node (yaml or midi).
                When recording the songbar should probably already have an indication of length in
                bars (but the timesignature and tempo must be known). Can this be retrieved from
                the 'Clock' events? How does that work?

C) aplaymidi. Take case B, press record and fill the songbar. Dump the record and stick a player
    to the bar. Press play on the songbar.

If this all works we have achieved the functionality of the three alsa progs. Nice, call it a
milestone and release version 0

=end
class AlsaPortNode < Midibox::Node
  private
    def initialize parent, qtc
      super
      self.title = 'Alsa Port'
#       tag "self.title = '#{title}'"
    end

    def unitsH
      4 # midiportname/events + brand + type + queuecontrol
    end
  public
    def self.inherited sub
#       tag "ADDING #{sub} to @@nodes"
      @@nodes << sub
    end

    def self.abstract?
      true
    end
end

class AlsaPortInNode < AlsaPortNode
  public
    def self.iconpath
      'file://' + ImageDir + #'alsaport.svg.gz'
        'keyboard_in.svg'  # BOGO quality . Inkscape is far too slow
    end

    def self.abstract?
    end
end

class AlsaPortOutNode < AlsaPortNode
  public
    def self.iconpath
#       tag "iconpath -> 'keyboard_out.svg'"
      'file://' + ImageDir + 'keyboard_out.svg'  # BOGO quality . Inkscape is far too slow
    end

    def self.abstract?
    end
end

Reform::createInstantiator(File.basename(__FILE__, '.rb'), AlsaPortInNode::qclass, AlsaPortInNode)
Reform::createInstantiator(File.basename(__FILE__, '.rb'), AlsaPortOutNode::qclass, AlsaPortOutNode)
