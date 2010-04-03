#!/usr/bin/ruby -w

module RRTS # namespace

  module Node

    require 'monitor'
    require_relative '../rrts'  # for tag etc

=begin rdoc
The Base Node class. It uses Monitor for simple syncing.
If we take a MIDI event as a message any node structure is nothing more than a
messageprocessing network of multiple consumers and multiple producers.

My solution is to use Threads for the producers and Fibers for the consumers.
This allows us to avoid the use of callbacks in the consumers which is awkward
(since state has to be kept within instance variables, instead of local variables).

Note: maybe Monitor is a bit fat. It may become an include in Filter and Consumer
=end
    class Base < Monitor
      private
      # Create a new node
      def initialize options = nil
        super()
        @consumers = []
        @producercount = 0
        options.each { |k, v| parse_option(k, v) } if options
      end

      # FIXME. this is a mess!
      def parse_option k, v
        case k
        when :split_channels, :combine_notes, :combine_progchanges, :combine_lsb_msb,  # ????
             :spam, :write_ahead, :sleeptime
        else raise RRTSError, "illegal option '#{k}' for #{self.class}"
        end
      end

      # Basic consuming fiber structure. The event handling is all within an
      # exclusive block.  To stop, the producer must send a nil (this is handled
      # automatically by the Producer class).
      def each_fiber when_done = nil
        synchronize { @producercount += 1 }
        Fiber.new do |ev|
          begin # ensure
            loop do
              synchronize do
                if ev
                  yield(ev)
                else
                  raise StopIteration if (@producercount -= 1) == 0
                  # interesting enough a break dissolves!!!
                  # and return is illegal here
                end
              end # synchronize
              ev = Fiber.yield
            end # loop
          ensure
            when_done.call if when_done
          end
        end
      end

      # keep repeating the passed block, until not interrupted (through Interrupt)
      def protect_from_interrupt
        loop do
          begin
            return yield
          rescue Interrupt
            # ignore it!
            next
          end
        end
      end

      # make connections from given producer(s) to ourselves
      def connect_from producer
        if Array === producer  #  .respond_to?(:each) <- dangerous. All nodes have :each!
          producer.each { |prod| prod >> self }
        else
          producer >> self
        end
      end

      public

      # Add one or an array of consumers
      def >> consumer
        consumer = [consumer] unless consumer.respond_to?(:to_ary)
        @consumers += consumer.to_ary
        self
      end

=begin rdoc
this method should overriden by consumers and filters
to do something different.
However it must return the result of each_fiber(!)

To push things to a consumer use:
    consume = consumer.consume
    source.each do |ev|
      # process 'ev'
      consume.resume ev
   end

The default Base behaves like /dev/null in that sense.

You can pass a lambda to 'each_fiber' to be called when done. (in fact it is ensured to be called)
See Base#each_fiber.

However, an alternative strategy is available.
If producer has a method to_chunk we can chunkify the producer and use the chunk as our
producer. We can then actively consume it.
It is also possible to dump a chunks tracks but not the events, and use each_fiber to
receive the events to dump.

Example: midifilereader can dump a chunk with all its tracks. But is also possible to just send
it the events. It then creates a default chunk with a single default track.
=end
      def consume producer, &when_done
        each_fiber(when_done) { |ev| }
        # *IMPORTANT*: any code here is executed BEFORE the loop!!
        # I mean to say, there should not be any code here. It must return
        # the result from the 'each_fiber' call.
      end

      # passing complete chunks is a very quick way of passing messages.
      def chunk
        nil
      end

      attr :consumers # for debugging purposes currently BAD EFFECTS!!! AAARGHH
    end

=begin rdoc
A Producer is a producer of events.
=end
    class Producer < Base
      include Enumerable # since we use 'each' already

      private
=begin rdoc
      Create a new producer.
      Valid options are:
      spam:: use spamming mode. If so the producer returns events as fast as possible.
             Setting this will ignore +write_ahead+
      full_throttle:: same as spam
      write_ahead:: number of seconds to be ahead with producing events. If the next event
                    is scheduled more than this away, we sleep for +sleeptime+ seconds.
                    Default is 3.
      sleeptime:: number of seconds to sleep if too far ahead. Default is 2.

      IMPORTANT: these options only work for the 'produce' and 'run' call and not for 'each' in
      general (as I am lazy and otherwise all implementors must add the same timing sequence
      over and over (3 times for now)).
      Also it is convenient having each always use 'spam' mode.
=end
      def initialize options = nil
        @write_ahead = 3
        @sleeptime = 2
        @spam = false
        @threads = true
        super
      end

      def parse_option k, v
        case k
        when :spam, :full_throttle then @spam = v
        when :write_ahead then @write_ahead = v
        when :sleeptime then @sleeptime = v
        when :threads then @threads = v
        else super
        end
      end

      def send_nils_to(cons)
        protect_from_interrupt do
          cons.each do |out|
            begin
              out.resume nil
            rescue FiberError
              # ignore, normal if Fiber already exited (p.e. on an Interrupt)
            end
          end
        end
      end

      # code run by the thread
      def run_thread
        # the consumers MUST be created within the thread!
        cons = @consumers.map{|consumer| consumer.consume(self) }
        cons.delete(nil)
        # cannot break nor return
        unless cons.empty?
          begin
            realtime_0 = Time.now
            each do |ev|
              unless @spam
                tick = ev.tick
                pps = tempo.pps # the initial value is only a default. It may change
                    # it is likely that the value is correct after each has been called.
                    # does it really matter?
                diff = (Float === tick ? tick : tick.to_f / pps) - (Time.now - realtime_0)
                if diff > @write_ahead
#                   tag "producer will sleep for #@sleeptime seconds"
                  sleep @sleeptime
                end
              end
              cons.each { |out| out.resume ev }
            end
          rescue Interrupt
            send_nils_to(cons)
          ensure
            send_nils_to(cons)
          end
        end
      end

      public
#       def has_tracks?
#         false
#       end

      # returns a default tempo
      def tempo
        require_relative '../tempo'
        Tempo.new
      end

      # returns true if the node floods the 'each' method.
      # For example, reading from a file will give us a records almost immediately.
      # If false then we need additional flushes on the connected outputnode.
      # Putting it in another manner: returning true means that each will virtually not block
      def spamming?
        @spam
      end

      # Returns a flat array of all contributing nodes. Track compatibility method
      # we must assume the node has events so it behaves like a single eventsource.
      # good enough for 'listing'
#       def listing
#         [self]
#       end

      # Default sequencenumber, always 0. Track compatibility method
#       def sequencenr
#         0
#       end

      # Track compatibility method.
#       def chunk
#         nil
#       end

      # Track compatibility method. Default nil
#       def voicename
#         nil
#       end

=begin rdoc
Example of the structure of a produce method. To override, keeping the same structuring.
It would be better though to simply override 'each'.

Note it returns a thread, and that 'join' should be called upon it
=end
      def produce
        Thread.new { run_thread }
      end

      # short for 'produce.join' which works fine for simple tests
      def run
        @threads ? produce.join : run_thread
      end
    end # class Producer

    # Almost (as in almost) the same as Base
    class Filter < Base
      include Enumerable
      private

      # create a new filter. If +producer+ is set we connect to it, but it can also be
      # an array of producers.
      # Ther +condition+ is the actual filter proc. If not given it is effectively
      # equal to { |ev| true }. It should accept a single argument and return a boolean
      # It is also possible to pass the condition in +options+.
      def initialize producer = nil, options = nil, &condition
        @condition = condition
#         tag "Filter.new, condition=#{@condition.inspect}"
        @spam = producer && producer.spamming?
        super(options)
        connect_from(producer) if producer
      end

      # override
      def parse_option k, v
        case k
        when :condition then @condition = v
        else super
        end
      end

      # override
      def each_fiber when_done = nil
        synchronize { @producercount += 1 }
        Fiber.new do |ev|
          begin
            loop do
              synchronize do
                yield ev
                raise StopIteration if ev.nil? && (@producercount -= 1) == 0
              end
              ev = Fiber.yield
            end
          ensure
            when_done.call if when_done
          end
        end
      end

      # internal handler for consumer part.
      # ev cannot be nil.
      # if an override does not call super the event is effectively discarded.
      def handle_event ev, cons
        cons.each { |out| out.resume ev }
      end

      public

      #override
      def consume producer, &when_done
        @spam = producer.spamming?
        cons = @consumers.map { |consumer| consumer.consume(self) }
        cons.delete(nil)
        return nil if cons.empty?
        each_fiber(when_done) do |ev|
          if ev.nil?
            # this is an obligation and inconvenient for handle_event overrides
            cons.each { |out| out.resume nil }
          else
#             tag "calling handle_event, based on #@condition"
            handle_event(ev, cons) if !@condition || @condition.call(ev)
          end
        end
      end

      # basicly, when we are attached to a spamming producer
      def spamming?
        @spam
      end
    end # class Filter

    # Consumer class. Currently empty
    Consumer = Base

    # Peekable improves Enumerator with a 'peek' method
=begin
    class Peekable < Enumerator
      private

      alias :old_next :next

      # any obj supporting _method_ can be passed
      # the result is an Enumerable (and Enumerator) supporting peek
      # as well as next.
      # So if something support each, but not peek, we can use this
      # class as a wrapper.
      def initialize(obj, method = :each, *args, &block)
#         tag "Peekable.initialize called"
        super
        begin
          @lookahead = old_next
        rescue StopIteration
          @lookahead = nil
        end
      end

      # override
      public
      def next
#         tag "Peekable.next called"
        raise StopIteration.new unless @lookahead
        r = @lookahead
        begin
          @lookahead = super
        rescue StopIteration
          @lookahead = nil
        end
        r
      end

      def peek
        @lookahead
      end

      def rewind
        super
        begin
          @lookahead = self.next
        rescue StopIteration
          @lookahead = nil
        end
      end
    end# class Peekable
=end

  end # Node
end # module RRTS namespace

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
cool to morph a vienna walz into a samba?
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
19) echoes... almost forgot this one.

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

Generic interface to nodes
Do all nodes have an IO interace?  For example, should you be able to use a midifilereader
as an output node.  This could be usefull to add a midifile to a song already being played.
We could then easily chain together 5 midifilereaders, reading 5 midifiles simultaneously.

Still there is a performance problem. It would mean that a midifilereader needs to juggle between
reading from a file (or pipe) and between other events.

Could use a separate MergerNode to do the merging. There is another problem looming up.
For nodes to merge properly they need a 'peek' operation.
This can be solved generically by using yet another layer that calls upon next, but has a
single lookahead element.
