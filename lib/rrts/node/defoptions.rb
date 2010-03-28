# The reverse of yamlreader
module RRTS #namespace

  require_relative 'node'

  module Node

    class DefaultOptions
      private
      def initialize arguments = ARGV
        require 'optparse'
        @input = @output = nil # stdin + stdout
        opts = OptionParser.new
        require_relative '../sequencer'
        @clientname = 'rplayer'
        @spam = false
        @blockingmode = true
        @write_ahead = 3
        Sequencer.new do |seq|
          opts.banner = "Usage: #$PROGRAM_NAME [options]"
          opts.on('-h', '--help', 'this help') { puts opts.to_s; exit 1 }
          opts.on('-V', '--version', 'show_version') do
            puts "#$PROGRAM_NAME version #{$PROGRAM_VERSION || '1.0'}"
            exit 0
          end
          opts.on('-c', '--clientname=VAL', 'use this name for the sequencer') do |name|
            @clientname = name
          end
          opts.on('--spam', 'flood the output') { @spam = true }
          opts.on('-l', '--list-ports', 'list all available ports') do
            puts(" %-6s  RW  %-32s  %s" % ['Port', 'Client name', 'Port name'])
            for portname, port in seq.ports
              next if port.system?
              r = port.capability?(:read, :subscription_read)
              w = port.capability?(:write, :subscription_write)
              next unless port.type?(:midi_generic) && (r || w)
              printf("%3d:%-3d  %s  %-32.32s  %s\n", port.client_id, port.port,
                     r ? w ? 'RW' : 'R' : 'W', port.client.name, portname)
            end
            exit 0
          end
          opts.on('-i', '--input=VAL') { |arg| @input = arg }
          opts.on('-o', '--output=VAL') { |arg| @output = arg }
          opts.on('--nonblocking') { @blockingmode = false }
          opts.on('--write_ahead=VAL', 'in seconds', Integer) { |arg| @write_ahead = arg }
          opts.parse arguments
        end # close Sequencer
      end # initialize

      def escape_shell_single_word token
        begin
          require 'escape'
        rescue LoadError
          raise RTTSError.new("could not load 'escape', try 'sudo gem install escape'")
        end
        Escape.shell_single_word(token)
      end

      public

      attr :input, :output

      # create an input node belongning to input
      def input_node
        case @input
        when nil then require_relative 'yamlreader'; YamlPipeReader.new
        when /\.yaml$/ then require_relative 'yamlreader'; YamlFileReader.new(@input)
        when /\.ygz$|\.yaml.gz$/
          require_relative 'yamlreader'
          YamlPipeReader.new("zcat #{escape_shell_single_word(@input)}") #.tap{|t|tag "t=#{t}"})
        when /\.midi?/i
          require_relative 'midifilereader'
          MidiFileReader.new(@input)
        else
          todo 'read from alsaport'
        end
      end

      # create an output node belongning to output
      def output_node
        case @output
        when nil then require_relative 'yamlwriter'; YamlPipeWriter.new
        when /\.yaml$/ then require_relative 'yamlwriter'; YamlFileWriter.new(@output)
        when /\.ygz$|\.yaml.gz$/
          require_relative 'yamlwriter'
          YamlPipeWriter.new("gzip --best > #{escape_shell_single_word(@output)}")
        when /\.midi?/i
          require_relative 'midifilewriter'
          MidiFileWriter.new(@output)
        else
          require_relative 'player'
          Player.new(@output, clientname: @clientname, spam: @spam, blockingmode: @blockingmode,
                     write_ahead: @write_ahead)
        end
      end
    end # class DefaultOptions
  end # module Node
end # module RRTS