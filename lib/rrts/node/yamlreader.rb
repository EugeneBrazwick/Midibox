#!/usr/bin/ruby -w

module RRTS

  require_relative '../rrts'
  require_relative 'node'

  module Node
    class YamlIOReader < Producer
      private
      def initialize io, options = nil
        @auto_close = true
        super(options)
        @io = io # to read from
        require 'yaml'
        @yaml_stream = YAML.load_stream(@io)
      end

      def parse_option k, v
        case k
        when :auto_close then @auto_close = v
        else super
        end
      end

      public
      def each &block
        return @yaml_stream.documents.to_enum unless block
        begin
          @yaml_stream.documents.each &block
        ensure
          @io.close if !@io.closed? && @auto_close
        end
      end

    end # class YamlIOReader

    class YamlFileReader < YamlIOReader
      private
      def initialize filename, options = nil
        super(File.open(filename, 'r'), options)
      end
    end

    class YamlPipeReader < YamlIOReader
      private
      def initialize io = nil, options = nil
        case io
        when nil
          tag("READING FROM STDIN !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
          io = STDIN
        when String, Array, Integer
          tag "popen #{@io.inspect}"
          io = IO.popen(io, 'r')
#           (options ||= {})[:auto_close] = true
#           io = IO.open(io, 'r')  ???????????????????????????????????????????????????????
#           (options ||= {})[:auto_close] = true
        when IO
          (options ||= {})[:auto_close] = false
        else
          raise RRTSError.new("Cannot open '#{io}'")
        end
        super(io, options)
      end
    end
  end
end

if __FILE__ == $0
  include RRTS
  include Node
=begin
  require_relative 'midifilereader'
  r = MidiFileReader.new('../../../fixtures/eurodance.midi',
                         combine_notes: true, combine_progchanges: true,
                         split_tracks: true
                        )
  require_relative 'yamlwriter'
  YamlFileWriter.new('/tmp/eurodance1.yaml', r)
=end
  require_relative 'yamlwriter'
  r2 = YamlFileReader.new('/tmp/eurodance1.yaml')
  YamlFileWriter.new('/tmp/eurodance2.yaml', r2)
end