#!/usr/bin/ruby -w

module RRTS
  module Node

    require_relative 'node'

    # this class is related to MidiIOWriter and YamlIOWriter.
    # this time, it writes to a sequencer
    class Player < Base

      # for #new
      Blocking = false
      # for #new
      NonBlocking = true

      private
=begin rdoc
Create a new player
If _input_node_ is not nil it immediately serve as input. The constructor will then not
return until the input is exhausted
Valid options are:
  [ name ]  Name of the client, default is 'rplayer'
  [ clientname ] Alias for _name_.
  [ client_name ] Alias for _name_.
  [ end_delay ] Sleeptime when quiting, default nil (== not). Do not pass 0.
  [ blockingmode ] Blocking is the default
  [ full_throttle ] Spam the output queue if true. This disabled the write_ahead and is default false
  [ write_ahead ] In seconds. Default 3.0. Time to write ahead. Using tempo and ticks to keep
      in sync. When the next is scheduled beyond this time we perform sleep(1).
      This is ignored in _spam_ mode.
  [ spam ] Same as full_throttle
=end
      def initialize dest_port_specifier, input_node = nil, options = {}
        (options, input_node = input_node, nil) if Hash === input_node
        # candidate option:
        # [ threaded ] Create the sequencer in a thread. Doing this will not prevent ruby from
        # being locked up. Do not use blockingmode.
        @dest_port_specifier = dest_port_specifier
        @name = 'rplayer' # name for the client
        @end_delay = nil
        @blockingmode = Blocking
        @spam = false
        @write_ahead = 3.0
        for k, v in options
          case k
          when :name, :clientname, :client_name then @name = v
          when :end_delay then @end_delay = v
          when :blockingmode then @blockingmode = v
          when :spam, :full_throttle then @spam = v
          when :write_ahead then @write_ahead = v.to_f
          else raise RRTSError.new("illegal option '#{k}' for Player")
          end
        end
        connect_to(input_node) if input_node
      end

      # keep looping if interrupted
      def protect_from_signals
        loop do
          begin
            return yield
          rescue Interrupt
            # ignore it!
            next
          end
        end
      end
    public

      # override
      def connect_to input_node
        chunk = input_node.chunk
        require_relative '../sequencer'
        Sequencer.new(@name, blockingmode: @blockingmode) do |seq|
          #calculate length of the entire file
          source = MidiPort.new(seq, @name + '_in', midi_generic: true, application: true)
          dest = seq.parse_address @dest_port_specifier
          queue = seq.create_queue(@name + '_q', tempo: chunk.tempo)
=begin
          We send MIDI events with explicit destination addresses, so we don't
          need any connections to the playback ports.  But we connect to those
          anyway to force any underlying RawMIDI ports to remain open while
          we're playing - otherwise, ALSA would reset the port after every
          event.
=end
          source.connect_to dest
          queue.start
          # The queue won't be started until the START_QUEUE event is
          # actually flushed to the kernel, which is exactly what we want.
          noteons = {} # per per channel, per note
          max_tick = 0
          realtime_0 = Time.new #- @write_ahead # Time supports tv_sec and tv_nsec
          pps = input_node.tempo.pps # if no idiot changes this during play...
#           tag "realtime_0 = #{realtime_0}, pps=#{pps}"
          begin # of ensure block
            input_node.each do |event|
#               tag "handling event #{event}"
              event.sender_queue = queue
              event.source = source
              event.dest = dest
              max_tick = event.tick
              unless @spam
                # Or should we use our tempo?? They should probably be the very same??
                # TODO: which is it?
                diff = (Float === max_tick ? max_tick : max_tick.to_f / pps) -
                       (Time.new - realtime_0)
#                 tag "diff=#{diff}"
                if diff > @write_ahead
#                   tag "SLEEPING, since #{diff} > #@write_ahead"
                  seq.flush # !UURGHH
                  sleep 1
                end
# We should wait unless tick is less than write_ahead seconds away.
                # Simply by sleeping
              end
              case event
              when MetaEvent
                # ignore these
                next
              # when NoteEvent  assume this goes well?
              when NoteOnEvent
                # If you're wise, these will not be present in the input.
                # but the defaults in midifilereader are still bad.
                if event.velocity == 0 # it counts as a NoteOff then.
                  (noteons[event.channel] ||= {})[event.note] = nil
                else
                  (noteons[event.channel] ||= {})[event.note] = event
                end
              when NoteOffEvent
                (noteons[event.channel] ||= {})[event.note] = nil
              end
              seq << event
            end
          rescue Interrupt
#             tag "removing events from queue"
            protect_from_signals { seq.remove_events; seq.flush; seq.sync_output_queue }
          ensure
#             tag "ensure operational, noteons=#{noteons.keys.inspect}"
            hangs = false
              #       puts "channels=#{channels.keys.inspect}"
            for channel, data in noteons
              for note, event in data
                next unless event
#                 tag "sending kill for note #{note} on port #{k} on ch #{event.channel}"
                seq << NoteOffEvent.new(channel, note, direct: true, dest: dest,
                                        sender: source)
                hangs = true
              end
            end
            if hangs
#               tag "calling flush"
              seq.flush # is direct so should not matter
#               tag "call sync_output_queue"
              seq.sync_output_queue
              sleep @end_delay if @end_delay # prevent seq from closing down before the deed is done....
            end
#             tag "sending queue.stop to system_timer"
            #  schedule queue stop at end of song
            event = StopEvent.new queue, tick: max_tick, dest: seq.system_timer,
                                  sender_queue: queue, source: source
            seq << event
            # make sure that the sequencer sees all our events
            begin
#               tag "another flush"
              seq.flush
=begin
    There are three possibilities how to wait until all events have
    been played:
    1) send an event back to us (like pmidi does), and wait for it;
    2) wait for the EVENT_STOP notification for our queue which is sent
    by the system timer port (this would require a subscription);
    3) wait until the output pool is empty.
    The last is the simplest.
=end
#               tag "and another sync"
              seq.sync_output_queue
            rescue Interrupt
#               tag "interrupted, remove events"
              protect_from_signals { seq.remove_events; seq.flush; seq.sync_output_queue }
            end
            # give the last notes time to die away
            sleep(@end_delay) if @end_delay
          end  #ensure
        end # close sequencer
      end # connect_to
    end # class Player
  end # Node
end # RRTS

if __FILE__ == $0
  require_relative 'midifilereader'
  include RRTS
  include Node
  r = MidiFileReader.new('../../../fixtures/eurodance.midi')
  Player.new('20:1', r, blockingmode: Player::NonBlocking, name: 'test', spam: true)
end
