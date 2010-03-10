
__END__

A _node_ is a graphical notion.  Nodes are items that can be connected using
input and output _sockets_.

A _voice_ is a fixed single voice on a keyboard. A voice requires a single
MIDI channel. There is no notion of time.

A _track_ can have a single voice, but also an altered or extended voice. A track may
require more than one channel but is limited to 16. A track contains events.

A _chunk_ is a collection of tracks. A chunk may require more than 16 channels.
Chunks can be very small or extremely big.

A _block_ is an element of a musical score with a limited timerange. Typical is 6 or 8 bars.

A eventprocessor is the main kind of node. Its input is a chunk, and the output as well.
It is however possible to split off a single track or channel.

Each node has three ways of input or output
* a file or pipe. A midifile can perhaps be used here, but the format need to be streamable.
* a set of Alsa midi ports (since a port is limited to 16 channels)
* using a ruby enumerator/enumerable. We enumerate over a MidiEvent (virtual) array.

Nodes can use other nodes internally.
We need a node that can read from a file and produces MidiEvent[].
We need a node that can read 1 or more ports and produces MidiEvent[].
We need a node that writes to a file or pipe, and finally one that writes to 1 or more ports.

The pipe method allows us to pass track-meta-information like the name of the instrument.
The internal connection does not need this, if we assume that we can use MidiEvent#track
(not implemented currently).  The Alsa version cannot use this, but we can use the events
to locate the voice.

* A _device_ is a specific type of instrument.  We can store a library of all voices it supports,
    together with MIDI activation messagebytes.
* There is a fixed list of devices for instruments that are GM compatible.
* It is possible that a track has no voice assigned.  For simple recording and playback this
  can be usefull. But then we must make sure we use the same channel and device for playing
  as was used for recording.
* In general there must be setup that connects two midiports to a single device.
  For example, if we record from 20:0 we would need to write back to 20:1.  In fact it doesn't
  matter which device is behind it.
* Each nodeclass must get a executable container used for testing and demonstrating.  There could
  be a basic ruby script excepting a class and building the container around it.
  This container must be wedgeable in a MIDI connection. For example it must automatically
  connect 20:0 to in and out to 20:1.  If you switch local off on the keyboard, then the notes
  played will now sound through the node.

* Some nodes are producers, they have no input from other nodes.
* Similarly there are consumernodes
* Some nodes can be consumer or producers but not both.  We can combine a MidiFileReader
and a MidiFileWriter to a MidiFile node, with an option to read or write.

* Examples of non eventnodes.
  - shapenode. Sinoid or saw or blockwave producer. Can be used to periodically change events.
  - voicepicker. Use a random voice based on tags.
  - stylepicker. Use a random style, or a combination of existing styles.

* Simple nodes

1) NullNode. Generates nothing or eats all.
2) Identity. Does nothing
3) Dup. Duplicates a track, so we have two, or a single compound track. For example, a
  piano track can be duplicated to a string.
4) Gradient.  Maps a range to another.  Normally this would be applied to velocity, but
 some controlparametervalue can be used as well.
 For example a velocitygradient could map 64..127 to 0..127. This means all notes with
 a velocity below 64 or scratched, while keeping the max. velocity the same.
 Or the reverse 0..127 to 0..50.  Applied to the string track from 3) we would get a
 softer addition of the string to the piano notes.
 A setup of 64..127 to 64..127 would scratch all notes with values below 64, but otherwise
 leave them be.
5) Multiplier. Similar to a gradient this applies a factor to some parameter. The factor can be
a constant or be supplied by a node (like a sinoid generator).
6) Gate effects.  Limit or extend the duration of notes.  Could be done by previous nodes too
but it requires timevalues and not a simple range.
6) Tremolo. Replace a note with a range of short ones.
7) Parameter driven stuff.  Like an equalizer.  Its effect depends on the value of the input
parameter to use, in this case 'note'. That need than be mapped according to a waveshape (or
any function)
8) Morphers.  Gradually change the influence of two nodes over time. Would it not be
cool to morph a vienna wals into a samba?
9) Channelmerger.  Maps input from tracks to output with 16 channels max.
10) Channelmapper.  Can filter out channels, and duplicate them as well.
11) Chord generator.
12) Harmonizer.
13) Mixer/panner/recorder using overdubbing. Mix your tracks realtime, track by track, keeping
previous results save.
14) visualizers.  From simple information nodes to whatever.
15) Quantizer.  A quantizer that actually does not screw up your recording.
16) Metronome. Generating a regular pulse of some kind.
17) Crescendo. Replaces a specific note with a specific parameter change. So can use a specific
key to add crescendo's to the music.
18) notemapping. Inverting or shifting and modulating.

* Important concept:  original recording remain intact.  All operations following are merely
logical, though it should be possible to _realize_ parts.

* Need database of styles, independent of devices. These are basicly accompanying tracks based
on which chord you play.  Any chord can be added. If missing the nearest is picked.
Any note can be added, same rule. A style can have 10 levels (0..9), and the same rule applies.
Level 0 is the minimal implementation and level 9 is all out.  In case a level is not present
the nearest higher is picked (if available) and some stuff is then dropped.
A style has a its own directory with files containing the midirecordings. Each style is then
named for example pat:C#7:M7:9:4.   kind:notename:chordname:level:nrofbars.
Kind can be 'pat' or 'fill' or 'intro' or 'end'.  The notename can drop the octave, and
normally you would only supply a single one. A bass inversion could be added to the chordname.
