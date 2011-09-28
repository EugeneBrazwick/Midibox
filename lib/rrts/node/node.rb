#!/usr/bin/ruby -w

module RRTS # namespace

  module Node

    require 'monitor'
    require_relative '../rrts'  # for tag etc

# The Base Node class. It uses the standard ruby class Monitor for simple syncing.
# If we take a MIDI event as a message any node structure is nothing more than a
# messageprocessing network of multiple consumers and multiple producers.
#
# My solution is to use Threads for the producers and Fibers for the consumers.
# This allows us to avoid the use of callbacks in the consumers which is awkward
# (since state has to be kept within instance variables, instead of local variables).
#
# This way the processing can be done without creating queues.
#
# Note: currently the Consumer class is identical to Base itself.
#
# Note that Base supports attaching consumers to it. This is used by Producer,
# but also by intermediate nodes, that pass on events.
# However, Consumer will not use these, so it is a bit fat.
    class Base < Monitor
# Note: maybe Monitor is a bit fat. It may become an include in Filter and Consumer
      private
        # Create a new node. Possible options depend on the subclass, see
        # Producer::new
        def initialize options = nil
         # ALL DEFAULTS FOR OPTIONS MUST BE *before* THE super call!!!!
          @spam = false # ignore timings, just give all you got
#           tag "new #{self}"
          super()
#           tag "consumers := []"
          @consumers = []
          @producercount = 0
          options.each { |k, v| parse_option(k, v) } if options
#           tag "Parsed options, spam is now #@spam"
        end

        # FIXME. this is a mess!
        def parse_option k, v
          case k
          when :split_channels, :combine_notes, :combine_progchanges, :combine_lsb_msb,  # ????
               :write_ahead, :sleeptime  # VALID but ignored
          when :spam
            #tag "SEEN spam @spam := #{v}";
            @spam = v
          when :producer, :producers then connect_from(v)
          else raise RRTSError, "illegal option '#{k}' for #{self.class}"
          end
        end

        # Basic 'consuming' fiber structure. The event handling is all within an
        # 'exclusive' block.  To stop, the producer must send a nil message
        # (this is handled automatically by the Producer class).
        # See Fiber::new and Monitor#synchronize in the pickaxe/ri/rdoc.
        #
        # Note: the final +nil+ event is always yielded (for convenience)
        #
        # Parameters:
        # [when_done] if a proc is passed here it will always be executed when
        #             the fiber is done.
	# [&block] your event handler
	#
        # Example:
        #
        #    consumer = each_fiber { |event| puts event.to_s }
        #    event_source.each do |event|
        #      consumer.resume event
        #    end
        #
        def each_fiber when_done = nil
          synchronize { @producercount += 1 }
          Fiber.new do |ev|
            begin # ensure
              loop do
                synchronize do
                  yield ev
                  raise StopIteration if ev.nil? && (@producercount -= 1) == 0
                end # synchronize
                ev = Fiber.yield
              end # loop
            ensure
              when_done.call if when_done
            end
          end
        end

        # send nil events to each element in given consumerarray
        # consumers take this as a hint to stop erm... consuming
        def send_nils_to cons
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

        # keep repeating the passed block, until it completes without being interrupted
        # (through an Interrupt exception)
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

        # make connections from given producer(s) to ourselves. That is, we add ourselves
        # as a _consumer_ to each _producer_ given.
        # Whenever the producers will start sending events we will receive those in our
        # Base#consume method
        def connect_from producer
          if Array === producer  #  .respond_to?(:each) <- dangerous. All nodes have :each!
            producer.each { |prod| prod >> self }
          else
            producer >> self
          end
        end

      public

        # Add one or an array of consumers. Note that this code is *not* used by Consumer
	# Returns self
	# If this producer is a spammer, all consumer will become infected with it as well
	# This method can be called more than once
        def >> consumer
          if consumer.respond_to?(:to_ary)
            @consumers += consumer.to_ary
            # once spamming is true, it can no longer lose that status.
            # until dropping of clients becomes supported that is
            consumer.each { |c| c.spam = true if @spam }
          else
#             raise "programmererror in #{self.inspect}" unless @consumers
            @consumers << consumer
            consumer.spam = spamming? if @spam
          end
          self
        end

# this method should overriden by consumers and filters
# to do something different.
# However it must return the result of each_fiber(!)
#
# To push things to a consumer use:
#
#     consume = consumer.consume
#     source.each do |ev|
#       # process 'ev'
#       consume.resume ev
#    end
#
# The default Base behaves like /dev/null in that sense.
#
# You can pass a lambda to 'each_fiber' to be called once, when done. (in fact it is ensured to be called)
# See Base#each_fiber.
#
# However, an alternative strategy is available.
# If producer has a method to_chunk we can chunkify the producer and use the chunk as our
# producer. We can then actively consume it.
# It is also possible to dump a chunks tracks but not the events, and use each_fiber to
# receive the events to dump.
#
# Example: midifilereader can dump a chunk with all its tracks. But is also possible to just send
# it the events. It then creates a default chunk with a single default track.
        def consume producer, &when_done
          each_fiber(when_done) { |ev| }
          # *IMPORTANT*: any code here is executed BEFORE the loop!!
          # I mean to say, there should not be any code here. It must return
          # the result from the 'each_fiber' call.
        end

        # passing complete chunks is a very quick way of passing messages.
        def to_chunk
        end

        attr :consumers # for debugging purposes currently BAD EFFECTS!!! AAARGHH

        # returns true if the node floods the 'each' method.
        # For example, reading from a file will give us all records almost immediately.
        # So there is a choice in whether to actually send these events in one big
        # batch, or the control this.
        # If false then we need additional flushes on the connected consumers.
        # Putting it in another manner: returning true means that this Producer#each method
        # will never sleep.
        def spamming?
          @spam
        end

        attr_writer :spam
    end

# A Producer is a producer of events. And an event should suppot a 'tick'
# method which contains the timestamp when it should be fired.
# Timing can be disabled using the 'spam' option, so in that case I guess
# any ruby instance can serve as event
    class Producer < Base
      include Enumerable # since we use 'each' already

      private
#       Create a new producer.
#       Valid options are:
#       [:spam]] use spamming mode. If so the producer returns events as fast as possible.
#                Setting this to true will ignore +write_ahead+. The default value is +false+.
#       [:full_throttle] same as spam
#       [:write_ahead] number of seconds to be ahead with producing events. If the next event
#                      is scheduled more than this amount in the future, we sleep for +sleeptime+ seconds.
#                      Default is 3. This option conflicts with +spam+.
#       [:sleeptime] number of seconds to sleep if too far ahead. Default is 2. It is clear
#                    that it should be less than +write_ahead+.
#       [:threads] if +true+ (the default) Producer#run will fork a thread.
#
#       IMPORTANT: these options only work for the Producer#produce and Producer#run calls and
#       not for Producer#each in
#       general (as I am lazy and otherwise all implementors must add the same timing sequence
#       over and over (3 times for now)).
#       Also it is convenient having 'each' always use 'spam' mode.
        def initialize options = nil
          @write_ahead = 3
          @sleeptime = 2
          @threads = true
          super
        end

	# override
        def parse_option k, v
          case k
          when :spam, :full_throttle then @spam = v
          when :write_ahead then @write_ahead = v
          when :sleeptime then @sleeptime = v
          when :threads then @threads = v
          else super
          end
        end

        # code run by the thread. This is the core of what the Producer does:
        # - it takes its consumers and call 'consume' on each.
        # - the result is an array of Fibers.
        # - next we call Producer#each in a loop, which generates our events
        # - we pass the events to all consumers using Fiber#resume
        # - in all cases we end with sending +nil+ events to all consumers.
        #
        # Note that there is no support for adding and removing consumers
        # during the loop!
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
#                   tag "tick = #{tick.inspect}"
                  loop do
                    if Float === tick
                      diff = tick - (Time.now - realtime_0)
                    else
                      pps = tempo.pps # the initial value is only a default. It may change
                        # it is likely that the value is correct after each has been called.
                        # does it really matter?
                      diff = tick.to_f / pps - (Time.now - realtime_0)
                    end
                    break unless diff > @write_ahead
#                     tag "producer will sleep for #@sleeptime seconds (dif #{diff} > wa #@write_ahead), ev=#{ev.inspect}"
                    sleep @sleeptime
                  end # loop
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

        # returns a default Tempo instance
        def tempo
          require_relative '../tempo'
          Tempo.new
        end

# Example of the structure of a produce method. Implementation must override this method.
# It would be better though to simply override 'each' ??
#
# Note it returns a thread, and that 'join' should be called upon it.
# See Producer#run.
        def produce
          Thread.new { run_thread }
        end

        # short for 'produce.join' which works fine for simple tests
        def run
          @threads ? produce.join : run_thread
        end
    end # class Producer

    # Consumer class. Currently almost the same as Base.
    # However a Producer is no longer a Consumer
    class Consumer < Base
      private
        # Parameters:
        # [producer], a single Producer, or an array of them
        # [options], vor valid options see Base::new.
        def initialize producer = nil, options = nil
          super(options)
          connect_from(producer) if producer
        end
    end

    # Almost (as in almost) the same as Consumer
    class Filter < Consumer
      include Enumerable
      private

        # create a new filter.
        #
        # Parameter:
        # [producer] a Producer instance or an array of them. If supplied we connect to it/them using
        #            Base#connect_from. This will add these producers as our eventsources.
        # [options]. See Base::new. We also support +:condition: here. Same as passing it as third argument.
        # [condition] This is the actual filter block. If not given (or +nil+) it is effectively
        #             equal to { |ev| true }. It should accept a single argument and return a boolean.
        #             A returnvalue equivalent to +true+ (not nil/false) indicates the event will pass, 
	#	      otherwise it will vanish
        #             from the premises. The condition is never applied to nil events.
        def initialize producer = nil, options = nil, &condition
          @condition = condition
  #         tag "Filter.new, condition=#{@condition.inspect}"
          super
        end

        # override
        def parse_option k, v
          case k
          when :condition then @condition = v
          else super
          end
        end

        # internal handler for consumer part. This is called for events that pass the
        # condition test. Specialist filters may override this method.
        #
        # Parameters:
        # [ev] the event, cannot be nil.
        # [cons] the consuming fibers that connected to us. By default the event is
        #        send to each of them.
        #
        # See Mapper#handle_event
        def handle_event ev, cons
          cons.each { |out| out.resume ev }
        end

      public

        #override. Merges in the code of Producer#run_thread
        def consume producer, &when_done
          cons = @consumers.map { |consumer| consumer.consume(self) }
          cons.delete(nil) # how did these get in???
          return nil if cons.empty?
          each_fiber(when_done) do |ev|
  #             tag "calling handle_event, based on #@condition"
            handle_event(ev, cons) if ev.nil? || !@condition || @condition.call(ev)
          end
        end

    end # class Filter

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
