#!/usr/bin/ruby -w

# If things go wrong run 'bin/panic 20:1'

# When interrupted the caller thread now receives CTRL-C. It then sends nil
# which is the same as a normal end.
# So player manages now to shutdown when CTRL-C is pressed but this may take a few seconds
# (at most @write_ahead in the producer(!))
module RRTS
  module Node

    require_relative 'node'
    require_relative '../rrts'

    # this class is related to MidiIOWriter and YamlIOWriter.
    # this time, it writes to a sequencer
    class Player < Consumer

      # for #new
      Blocking = false
      # for #new
      NonBlocking = true

      private
# Create a new player
# If _input_node_ is not nil it immediately serves as input. The constructor will then not
# return until the input is exhausted.
# The +producer+ can be nil (default) or a single inputnode, or an array of inputnodes.
#
# *important*: I noticed delays if a Recorder node is present with a different client_name.
#
# Parameters:
# [dest_port_specifier] Any valid port specification like '14:0' or 'UM-2 MIDI 1' or a MidiPort (etc)
# [producer] optional parameter, can be replaced with +options+. If set it is the source for our data.
#            See Consumer::new
# [options] (can also be argument 2). Valid options are:
#           [ name ]  Name of the client, default is 'rplayer'
#           [ clientname ] Alias for _name_.
#           [ client_name ] Alias for _name_.
#           [ end_delay ] Sleeptime when quiting, default +nil+ (== not). Do not pass 0.
#           [ blockingmode ] can be +:blocking+ or +:nonblocking+ (or the constants Blocking/NonBlocking)
#                            +:blocking+ is the default
#           [ full_throttle ] Spam the output queue if +true=. This disables the +write_ahead+ and is default false
#           [ write_ahead ] In seconds. Default 3.0. Time to write ahead. Using tempo and ticks to keep
#                           in sync. When the next is scheduled beyond this time we perform sleep(1).
#                           This is ignored in _spam_ mode.
#           [ spam ] Same as full_throttle
      def initialize dest_port_specifier, producer = nil, options = nil
        (options, producer = producer, nil) if Hash === producer
#         tag "Player.new, options=#{options.inspect}"
        # candidate option:
        # [ threaded ] Create the sequencer in a thread.
        # IMPORTANT: defaults of options must be set BEFORE super is called
        @client_name = 'rplayer' # name for the client
        @end_delay = nil
        @blockingmode = :blocking
#         tag "Calling super with options: #{options.inspect}"
        super(producer, options)
#         tag "spamming  = #{spamming?}, spam=#@spam"
        @dest_port_specifier = dest_port_specifier
      end

      def parse_option k, v
        case k
        when :name, :clientname, :client_name then @client_name = v
        when :end_delay then @end_delay = v
        when :blockingmode
          case v
          when Blocking then @blockingmode = :blocking
          when NonBlocking then @blockingmode = :nonblocking
          else @blockingmode = v
          end
        else super
        end
      end

    public

      # override
      def consume producer, &when_done
#         tag "creating fiber, producer.spamming = #{producer.spamming?}"
        require_relative '../sequencer'
        existing = seq = Sequencer[@client_name]
        seq = Sequencer.new(@client_name, blockingmode: @blockingmode) unless existing
        source = MidiPort.new(seq, @client_name + '_in', midi_generic: true, application: true,
                              read: true, subs_read: true)
        dest = seq.parse_address @dest_port_specifier
=begin
        We send MIDI events with explicit destination addresses, so we don't
        need any connections to the playback ports.  But we connect to those
        anyway to force any underlying RawMIDI ports to remain open while
        we're playing - otherwise, ALSA would reset the port after every
        event.
=end
#         tag "connect #{source} to #{dest}"
        source.connect_to dest
        queue = nil # created on first Tempo event
        # The queue won't be started until the START_QUEUE event is
        # actually flushed to the kernel, which is exactly what we want.
        noteons = {} # per per channel, per note
        max_tick = 0
#           tag "realtime_0 = #{realtime_0}, pps=#{pps}"
        when_done = lambda do
                    # on closing !
          return unless queue # if no queue, then we haven't even started yet
          begin
            protect_from_interrupt do
#               tag "closing down, please wait. noteon.channels=#{noteons.keys.inspect}"
              hangs = false
              for channel, data in noteons
                for note, event in data
                  next unless event
    #                 tag "sending kill for note #{note} on port #{k} on ch #{event.channel}"
                  seq << NoteOffEvent.new(channel, note, tick: max_tick + 1, dest: dest,
                                          sender: source, sender_queue: queue)
                  hangs = true
                end
              end
              if hangs
#                 tag "calling flush"
                seq.flush # is direct so should not matter
#                 tag "call sync_output_queue"
                seq.sync_output_queue
              end
#               tag "sending queue.stop to system_timer"
              #  schedule queue stop at end of song
              event = StopEvent.new queue, tick: max_tick, dest: seq.system_timer,
                                    sender_queue: queue, source: source
              seq << event
            end # protect_from_interrupt
          ensure
            seq.flush
            seq.sync_output_queue
          end
          unless existing
            sleep(@end_delay) if @end_delay
            seq.close
          end
        end # lambda
        each_fiber when_done do |event|
          next unless event  # nil == EOD
          # handle event
#           tag "receiving event #{event}"
          event.sender_queue = queue
          event.source = source
          event.dest = dest
          max_tick = event.tick
          case event
          when MetaEvent, TrackEvent
            # ignore these
            next
          # when NoteEvent  assume this goes well?
          when TempoEvent
#             tag "got TempoEvent #{event}"
            unless queue
#               tag "setting up the queue, now we have the tempo, event.usecs_per_beat: #{event.usecs_per_beat}"
              queue = seq.create_queue(@client_name + '_q', tempo: event.usecs_per_beat)
              queue.start
              next  # the first Tempo event just starts the queue.
            end
          when NoteOnEvent
            # If you're wise, these will not be present in the input.
            # but the defaults in midifilereader are still bad.
            if event.velocity == 0 # it counts as a NoteOff then, so erase
              (noteons[event.channel] ||= {})[event.note] = nil
            else
              (noteons[event.channel] ||= {})[event.note] = event
            end
          when NoteOffEvent
            (noteons[event.channel] ||= {})[event.note] = nil
          end
#           tag "seq << #{event}"
          seq << event
#           tag "calling flush"
          # producers always send ahead,
#           unless producer.spamming?
          seq.flush
#           seq.sync_output_queue
#           tag "return to producer"
#           end
        end
      end # def consume
    end # class Player
  end # Node
end # RRTS

if __FILE__ == $0
  require_relative 'midifilereader'
  include RRTS
  include Node
  producer = MidiFileReader.new('../../../fixtures/eurodance.midi', threads: true)
      # threads: true locks up in 'event_output()'
  Player.new('20:1', producer, blockingmode: :nonblocking, client_name: 'test')
  begin
    producer.run
  rescue Interrupt
  end
end
