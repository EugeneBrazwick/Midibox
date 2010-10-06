#!/usr/bin/ruby -w

# The reverse of yamlreader
module RRTS #namespace

  require 'rrts/rrts'
  require 'rrts/node/node'

  module Node

    # class to create streamable yaml output
    class YamlIOWriter < Consumer
      private
      def initialize io, producer = nil
        super()
        @io = io # to write to
        producer >> self if producer
      end

      public

      # override
      def consume producer
        require 'yaml'
        each_fiber -> do
          #tag("CLOSING IO #{@io.inspect}")
          @io.close
          yield if block_given?
        end do |event|
          if event  # due to a change in the API all consumer now receive the closing nil.
            # this makes LastEvent a bit superfluous
            @io.write event.to_yaml
            @io.flush unless producer.spamming?
          end
        end
      end

    end # class YamlIOWriter

    # Convenience class for dumping to a named file
    class YamlFileWriter < YamlIOWriter
      private
      def initialize filename, producer = nil
        super(File.new(filename, 'w'), producer)
      end
    end # class MidiFileWriter

    class YamlPipeWriter < YamlIOWriter
      private
      def initialize io = STDOUT, producer = nil
        case io
        when String, Array
          io = IO.popen(io, 'w')
        when Integer
          io = IO.open(io, 'w')
        when IO
        else
          raise RRTSError.new("Cannot open '#{io}'")
        end
        super(io, producer)
      end
    end # class YamlPipeWriter

  end # Node
end # RRTS

if __FILE__ == $0
  include RRTS
  include Node
  require_relative 'midifilereader'
  input = MidiFileReader.new('../../../fixtures/eurodance.midi')
  YamlFileWriter.new('/tmp/eurodance.yaml', input)
  # there should be 8 tracks or so... There is 1....
end