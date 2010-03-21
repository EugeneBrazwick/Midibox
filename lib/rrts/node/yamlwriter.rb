#!/usr/bin/ruby -w

# The reverse of yamlreader
module RRTS #namespace

  require_relative '../rrts'
  require_relative 'node'

  module Node

    # class to create streamable yaml output
    class YamlIOWriter < Base
      private
      def initialize io, node = nil
        super()
        @io = io
        connect_to(node) if node
      end

      public
      # makes the dump
      def connect_to node
        require 'yaml'
        @io.write node.chunk.to_yaml
        node.each { |event| @io.write event.to_yaml }
      end

    end # class YamlIOWriter

    # Convenience class for dumping to a named file
    class YamlFileWriter < YamlIOWriter
      private
      def initialize filename, node = nil
        super(File.new(filename, 'w'), node)
      end
    end # class MidiFileWriter
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