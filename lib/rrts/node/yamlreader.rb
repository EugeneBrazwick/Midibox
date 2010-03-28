#!/usr/bin/ruby -w

module RRTS

  require_relative '../rrts'
  require_relative 'node'

  module Node
    class YamlIOReader < EventsNode
      private
      def initialize io, options = {}
        @io = io
        @chunk = nil
#         @auto_close = true
#         for k, v in options
#           case k
#           when :auto_close then @auto_close = v
#           end
#         end
      end

      public
      def each &block
#         tag "each"
        return to_enum unless block
#         begin
        chunk
        i = 1
        loop do
#           tag "fetch yaml_stream.documents[#{i}]"
          event = @yaml_stream.documents[i] or break
          i += 1
          # but the first item is the chunk
#           tag "chunk=@chunk, event=#{event}"
#           tag "event=#{event.inspect}"
          # reconnect the references as we read on...
          (event.track = @chunk.track_for(event)).events << event
          yield(event)
        end
# #         ensure
#           tag "IO CLOSE #{@io}"
#           @io.close if !@io.closed? && @auto_close
#         end
      end

      # override
      def chunk
        return @chunk if @chunk
#         tag "chunk request, no chunk read yet"
        # make sure all possible classes are available!
        require_relative 'chunk'
        require_relative 'track'
        # Must be here, even though chunks do not contain events@
        # However, the yamlstream will read ahead!!!
        require_relative '../midievent'
        @yaml_stream = YAML.load_stream(@io)
        # load_documents reads ahead and you cannot break it
        # and resume later!!!!
#         YAML.load_documents(@io) do |c|
#         YAML.parse_documents(@io) do |y|
#           c = y.transform
        c = @yaml_stream.documents[0]
#         tag "no chunk yet, calling fix_tracks, c=#{c}"
        c.fix_tracks
        return @chunk = c
      end
    end # class YamlIOReader

    class YamlFileReader < YamlIOReader
      private
      def initialize filename
        super(File.open(filename, 'r'))
      end
    end

    class YamlPipeReader < YamlIOReader
      private
      def initialize io = STDIN, options = {}
        case io
        when String, Array
          io = IO.popen(io, 'r')
          options[:auto_close] = true
        when Integer
          io = IO.open(io, 'r')
          options[:auto_close] = true
        when IO
        else
          raise RRTSError.new("Cannot open '#{io}'")
        end
        options[:internalize] ||= false
        super
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