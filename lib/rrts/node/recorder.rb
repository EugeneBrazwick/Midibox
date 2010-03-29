#!/usr/bin/ruby -w

module RRTS
  module Node

    require_relative 'node'
    require_relative '../rrts'  # for RRTSError

    # this class is related to MidiIOReader and YamlIOReader.
    # But now we read from one port (or several).
    class Recorder < EventsNode

      private

=begin rdoc
Create a new recorder. Parameters
src_port_specifier::  comma separated list of port specifiers. See Sequencer::parse_address
options::  a hash with the following names options:
  smpte_timing:: bool, set with syncing with movies etc.
  ticks:: ticks per pulse, default 384, or 40 if smpte_timing is set
  beats:: beats per minute, default 120
  frames:: frames per second, must be given
  blockingmode:: default true
  clientname:: default 'rrecorder'
  client_name:: alias
=end
      def initialize src_port_specifier, options = {}
        @src_port_specifiers = src_port_specifier.split(',')
        @smpte_timing = false
        @ticks = @frames = nil
        @beats = 120
        @client_name = 'rrecorder'
        @blockingmode = true
        for k, v in options
          case k
          when :smpte_timing then @smpte_timing = v
          when :ticks then @ticks = v
          when :blockingmode then @blockingmode = v
          when :beats then @beats = v
          when :frames then @frames = v
          when :clientname, :client_name then @client_name = v
          else raise RRTSError.new("illegal option '#{k}' for Recorder")
          end
        end
        @ticks = @smpte_timing ? 40 : 384 unless @ticks
        @ticks = 255 if @smpte_timing && @ticks > 255
      end

      public

      # enumerate the events
      def each &block
        return to_enum unless block
        require_relative '../sequencer'
        require_relative '../midiport'
        Sequencer.new(@client_name, blockingmode: @blockingmode) do |seq|
#           client = seq.client
          queue = seq.create_queue(@client_name + '_q', smpte_timing: @smpte_timing,
                                   frames: @frames, beats: @beats, ticks: @ticks)
          port_params = { write: true, subs_write: true, midi_generic: true, application: true,
                          midi_channels: 16, timestamping: true, timestamp_queue: queue,
                          port_specified: false
                        }
          ports = []
          source_ports = @src_port_specifiers.map { |port_name| seq.parse_address port_name }
          source_ports.each_with_index do |src, i|
            ports << (port = MidiPort.new(seq, @client_name + ('_p%02d') % (i + 1), port_params))
            port.connect_from src
          end
          queue.start
          seq.flush
          descriptors = seq.poll_descriptors
          loop do
            begin
              descriptors.poll
              event = seq.event_input
              case event
              when ClockEvent, TickEvent # do nothing
              else
                yield event
              end
            rescue Errno::EAGAIN
              sleep(seq.polltime)
            rescue Interrupt
              # silent break
              break
            end
          end # loop
        end # close Sequencer
      end # def each
    end # class Recorder

  end # module Node
end # module RRTS

if __FILE__ == $0
  include RRTS
  include Node
  input = Recorder.new('20:0')
  require_relative 'yamlwriter'
  YamlPipeWriter.new(STDOUT, input)
end