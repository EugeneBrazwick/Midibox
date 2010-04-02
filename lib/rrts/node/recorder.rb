#!/usr/bin/ruby -w

module RRTS
  module Node

    require_relative 'node'
    require_relative '../rrts'  # for RRTSError

    # this class is related to MidiIOReader and YamlIOReader.
    # But now we read from one port (or several).
    class Recorder < Producer

      private

=begin rdoc
Create a new recorder. Parameters
src_port_specifier:: array or comma separated list of port specifiers. See Sequencer::parse_address
options::  a hash with the following names options:
  smpte_timing:: bool, set with syncing with movies etc.
  ticks:: ticks per pulse, default 384, or 40 if smpte_timing is set
  beats:: beats per minute, default 120
  frames:: frames per second, must be given
  blockingmode:: default true
  clientname:: default 'rrecorder'
  client_name:: alias

More options as for Producer#new
=end
      def initialize src_port_specifier, options = nil
        @src_port_specifiers = src_port_specifier.respond_to?(:to_str) ?
                                 src_port_specifier.to_str.split(',') : src_port_specifier
        @smpte_timing = false
        @ticks = @frames = nil
        @beats = 120
        @client_name = 'rrecorder'
        @blockingmode = true
        super(options)
        @ticks = @smpte_timing ? 40 : 384 unless @ticks
        @ticks = 255 if @smpte_timing && @ticks > 255
        @spam = true #  override, since false will cannot possibly what you intended
#         tag "new Recorder, ticks=#@ticks, smpte_timing=#@smpte_timing, options=#{options.inspect}"
      end

      #override
      def parse_option k, v
        case k
        when :smpte_timing
          if @smpte_timing = v
            @beats = nil
          end
        when :ticks then @ticks = v
        when :blockingmode then @blockingmode = v
        when :beats
          if @beats = v
            @frames = nil
            @smpte_timing = false
          end
        when :frames
          if @frames = v
            @beats = nil
            @smpte_timing = true
          end
        when :clientname, :client_name then @client_name = v
        when :channel_split # ignored, has no meaning
        else super
        end
      end

      def run_recorder seq
#           client = seq.client
        queue = seq.create_queue(@client_name + '_q', smpte_timing: @smpte_timing,
                                 frames: @frames, beats: @beats, ticks: @ticks)
#         tag "created queue, tempo info: ppq=#{queue.tempo.ppq}, uspb=#{queue.tempo.usecs_per_beat}"
        port_params = { write: true, subs_write: true, midi_generic: true, application: true,
                        midi_channels: 16, timestamping: true, timestamp_queue: queue,
                        port_specified: false
                      }
        ports = []
        source_ports = @src_port_specifiers.map { |port_name| seq.parse_address port_name }
        source_ports.each_with_index do |src, i|
          ports << (port = MidiPort.new(seq, @client_name + ('_p%02d') % (i + 1), port_params))
#           tag "connect #{port} from #{src}"
          port.connect_from src
        end
#         yield(TrackCreateEvent.new)
#         tag "send initial TempoEvent"
        yield(TempoEvent.new(queue))
#         tag "starting queue"
        queue.start
        seq.flush
        descriptors = seq.poll_descriptors
        loop do
          begin
#             tag "thread is waiting for poll"
            descriptors.poll
            event = seq.event_input
            case event
            when ClockEvent, TickEvent # do nothing
#               tag "received CLOCK/TICK"
            else
              yield event
            end
          rescue Errno::EAGAIN
            sleep(seq.polltime)
          rescue Interrupt
            tag "Interrupt 'received'"
            # silent break. Unfortunately ruby SEGV's on a ^C within a thread
            return
          end
        end # loop
      end

      public

      # enumerate the events
      def each(&block)
        return to_enum unless block
        require_relative '../sequencer'
        if seq = Sequencer[@client_name]
#           tag "dipping in existing sequencer #@client_name"
          run_recorder(seq, &block)
        else
#           tag "each, creating sequencer '#@client_name'"
          Sequencer.new(@client_name, blockingmode: @blockingmode) do |seq2|
            run_recorder(seq2, &block)
          end # close Sequencer
        end
#       rescue Interrupt  # ^C -> SEGV
        # return quietly
      end # def each

      # we obviously never spam
#       def spamming?
#         false
#       end
    end # class Recorder

  end # module Node
end # module RRTS

if __FILE__ == $0
  include RRTS
  include Node
  input = Recorder.new('20:0', threads: true)
  require_relative 'yamlwriter'
  YamlPipeWriter.new(STDOUT, input)
  input.run
end