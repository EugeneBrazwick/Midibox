# The reverse of yamlreader
module RRTS #namespace

  require_relative 'node'

  module Node

    class DefaultOptions
      private
      # passing a Hash is not yet supported
      def initialize arguments = []
        raise RRTSError, 'evil input' unless Array === arguments
#         tag "DefaultOptions.new, arguments = #{arguments.inspect}"
        @input = @output = nil # stdin + stdout
#         @wrap = false
        @client_name = 'rclient'
        @spam = false
        @blockingmode = true
        @write_ahead = 3
        @smpte_timing = false
        @beats = 120  # quarters per minute
        @frames = nil  # not 0!
        @split_channels = false
        @ticks = nil   # default 384 ticks per quarter or 40 for smpte_timing
        @combine_lsb_msb = @combine_notes = @combine_progchanges = true
        @sleeptime = 2
        require_relative '../sequencer'
        Sequencer.new do |seq|
          require 'optparse'
          opts = OptionParser.new
          opts.banner = "Usage: #$PROGRAM_NAME [options]"
          opts.on('-h', '-?', '--help', 'this help') { puts opts.to_s; exit 1 }
          opts.on('-V', '--version', 'show_version') do
            puts "#$PROGRAM_NAME version #{$PROGRAM_VERSION || '1.0'}"
            exit 0
          end
          opts.on('-c', '--clientname=VAL', '--client-name=VAL',
                  'use this name for the sequencer, default rclient') do |name|
            @client_name = name
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
          opts.on('-i', '--input=VAL', 'port or filename, default STDIN') { |arg| @input = arg }
          opts.on('-o', '--output=VAL', 'port or filename, default STDOUT') { |arg| @output = arg }
          opts.on('--[no-]blocking', 'set blocking mode of the sequencer, default blocking') { |arg| @blockingmode = arg }
          opts.on('--write_ahead=VAL', 'in seconds', Integer) { |arg| @write_ahead = arg }
          opts.on('-s', '--[no-]channel-split', '--[no-]split-channels',
                  'split channels from MIDI file, default false ') { |arg| @split_channels = arg }
          opts.on('--[no-]combine-notes', 'combine note events') { |arg| @combine_notes = arg }
          opts.on('--[no-]combine-progchanges', 'combine progchanges') { |arg| @combine_progchanges = arg }
          opts.on('--[no-]combine-lsb_msb', 'combine control14 events') { |arg| @combine_lsb_msb = arg }
          opts.on('--sleeptime=VAL', Integer, 'when ahead of writing') { |arg| @sleeptime = arg }
          opts.on('--no-tampering', 'leave all events as is') do
            @split_channels = @combine_lsb_msb = @combine_notes = @combine_progchanges = false
          end
          opts.on('-b', '--bpm=VAL', '--beats=VAL', Integer,
                  'tempo in beats per minute') do |bpm|
            raise OptionParser::InvalidArgument.new("Invalid tempo #{bpm}") unless (4..6000) === bpm
            @beats = bpm
            @smpte_timing = false
          end

          opts.on('-f', '--fps=VAL', '--frames=VAL', Integer, [24, 25, 39, 30],
                  'use frames per second') do |fps|
            @frames = fps
            @smpte_timing = true
          end

          opts.on('-t', '--ticks=VAL', Integer, 'use ticks per beat or frame') do |ticks|
            raise OptionParser::InvalidArgument.new('Invalid number of ticks') unless (1..0x7fff) === ticks
            @ticks = ticks
          end

          opts.on('-w', '--wrap=PORTSSPEC',
                  'single client, or comma separated porttuple (i,o)') do |portsspec|
            if portsspec =~ /([-,]*),([-,])*/
              # we could maybe get away assigning MidiPort, but technically
              # they hold a ref to the sequencer, and it will close
              # the addresses will probably still work, but connect_to may act weird
              # So I assign the harmless addresses here
              @input, @ouput = [seq.port($1).address], seq.port($2).address
            else
              client = seq.client(portsspec)
              # filter the input and output ports. Should be r + w
              ports = client.ports
              raise RRTSError.new("client does not identify exactly two ports") if ports.length != 2
              if !ports[0].capability?(:read, :subscription_read) ||
                 !ports[0].type?(:midi_generic) ||
                 !ports[1].capability?(:write, :subscription_write) ||
                 !ports[1].type?(:midi_generic)
                raise RRTSError.new("Port 0 must be read+MIDI, port 1 must be write+MIDI. This is not the case.")
              end
              # see comment above
              @input, @output = [ports[0].address], ports[1].address
            end
          end # --wrap

          opts.parse arguments
          @ticks = @smpte_timing ? 40 : 384 unless @ticks
          @ticks = 255 if @smpte_timing && @ticks > 255

        end # close Sequencer
      end # initialize

      def escape_shell_single_word token
        begin
          require 'shellwords'
        rescue LoadError
          raise RTTSError, "could not load 'escape', try 'sudo gem install escape'"
        end
        Shellwords.shellescape token
      end

      public

#       attr :input, :output #, :ticks, :beats, :frames, :write_ahead, :client_name

=begin
      def smpte_timing?
        @smpte_timing
      end

      def blocking?
        @blockingmode
      end

      def spam?
        @spam
      end
=end

      # create an input node belongning to input
      def input_node
#         tag "input_node, input=#@input"
        options = { spam: @spam, write_ahead: @write_ahead, sleeptime: @sleeptime,
                    split_channels: @split_channels,
                    combine_lsb_msb: @combine_lsb_msb,
                    combine_notes: @combine_notes,
                    combine_progchanges: @combine_progchanges
                  }
        case @input
        when nil
          require_relative 'yamlreader'
#           tag "ALERT READING FROM STDIN!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
          YamlPipeReader.new nil, options
        when /\.yaml$/
          require_relative 'yamlreader'
          YamlFileReader.new(@input, options)
        when /\.ygz$|\.yaml.gz$/
          require_relative 'yamlreader'
          YamlPipeReader.new("zcat #{escape_shell_single_word(@input)}", #.tap{|t|tag "t=#{t}"})
                             options)
        when /\.midi?/i
#           tag "Returning MidiFileReader(input=#@input)"
          require_relative 'midifilereader'
          MidiFileReader.new(@input, options)
        else
          require_relative 'recorder'
          Recorder.new(@input,
                       options.merge({ client_name: @client_name,
                                       blockingmode: @blockingmode,
                                       smpte_timing: @smpte_timing, frames: @frames, beats: @beats,
                                       ticks: @ticks }))
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
          Player.new(@output, client_name: @client_name, spam: @spam, blockingmode: @blockingmode,
                     write_ahead: @write_ahead, sleeptime: @sleeptime)
        end
      end
    end # class DefaultOptions
  end # module Node
end # module RRTS