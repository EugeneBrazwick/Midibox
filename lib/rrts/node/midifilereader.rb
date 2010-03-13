#!/usr/bin/ruby -w
=begin
 * This is based on aplaymidi.c by Clemens Ladish
 *
 * Copyright (c) 2004-2006 Clemens Ladisch <clemens@ladisch.de>
 * Copyright (c) 2010 Eugene Brazwick <eugene.brazwick@rattink.com>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
=end

module RRTS #namespace

  module Node

    require_relative '../rrts'
    require_relative 'node'

    # The Parser will be a class that is basically used in the chunk constructor.

=begin rdoc
  The parser scans a midifile and records its tracks in a chunk.
  It does this by storing the synthesized parsernodes into the passed builder
  using '<<'. The builder should take care of the level.
  The parser maintains a reference to the generated tracks and chunks, as long
  as they are being read.
  When done it stores an EOFError exception into the builder.

  ----

  The port indices as read from the MIDI file remain as is within the tracks.
  Each event build will contain a track reference so this portindex can then be
  used by the consumer.  Note that is NOT a port id, but a indication of a portindex.
  For example if the recorder used three inputports then the indices 0, 1 and 2
  are used. But they player may not even have three ports available, and even if so,
  they may refer to different devices than what was recorded.

  Supported options:
  * split_tracks, default false. Only works if internalize is true.
  * combine_notes, default false (but may likely change).
  If internalize is false this will delay the emission of the Note events
  until the NoteOff is read
  * combine_progchanges, default false (but may likely change)

=end
    class MidifileParser
      private
      # the parser will not close the io.
      def initialize io, builder, &block #, options
        @io, @builder, @block = io, builder, block
        @pos = 0 # io.pos does not work on pipes. So there...
=begin  These options are for the builder?
        Well we have two builders. Although the code could be shared.
        And I think that would be better.

        OR we can use a specific intermediate that does the necessary transformations
        passing other options to the underlying system.

        @split_tracks = @combine_notes = @combine_progchanges = false
        require_relative 'chunk'
        for k, v in options
          case k
          when :split_tracks then @split_tracks = v
          when :combine_notes then @combine_notes = v
          when :combine_progchanges then @combine_progchanges = v
          end
        end
=end
        case read_id # .tap {|v| tag "v=#{v}, MTHD=#{MTHD},RIFF=#{RIFF}"}
        when MTHD
          read_smf
        when RIFF
          read_riff
        else
          raise RRTSError.new("#@io is not a Standard MIDI File")
        end
      end

      def read_byte
        @pos += 1
        @io.readbyte  # will throw EOFError on EOF
      end

      # read a bytestring
      def read len
        s = ''
        s.force_encoding 'ascii-8bit'
        len.times { s += read_byte.chr }
        s
      end

      #  reads a little-endian 32-bit integer
      def read_32_le
        #       int value;
        a = read_byte
        b = read_byte
        c = read_byte
#         tag "a=#{a.chr}, b=#{b.chr}, c=#{c.chr}"
        a | (b << 8) | (c << 16) | (read_byte << 24)
      end

      # /* reads a 4-character identifier */
      alias :read_id :read_32_le

      # Used to create the constants below at class-parse-time
      def self.make_id c
        c.force_encoding 'ascii-8bit'
        c[0].ord | (c[1].ord << 8) | (c[2].ord << 16) | (c[3].ord << 24)
      end

      MTHD = make_id('MThd')
      RIFF = make_id('RIFF')
      MTRK = make_id('MTrk')
      RMID = make_id('RMID')
      DATA = make_id('data')

      # reads a fixed-size big-endian number
      def read_int bytes = 4
        #   int c, value = 0;
        value = 0
        bytes.times { value = (value << 8) | read_byte }
        #   puts "read_int -> #{value}"
        value
      end

      # reads a variable-length number
      def read_var
        #       int value, c;
        c = read_byte
        value = c & 0x7f
        return value if (c & 0x80) == 0
        c = read_byte
        value = (value << 7) | (c & 0x7f)
        return value if (c & 0x80) == 0
        c = read_byte
        value = (value << 7) | (c & 0x7f)
        return value if (c & 0x80) == 0
        c = read_byte
        raise RRTSError.new("Illegal var-length in stream") if (c & 0x80) != 0
        (value << 7) | c
      end

      def skip nbytes
        nbytes.times { read_byte }
#         @io.seek nbytes, IO::SEEK_CUR  does not work on pipes, obviously
      end

      def read_error
        raise RRTSError.new("#@io: invalid MIDI data (offset #{@pos})")
      end

      # read 7bit components.
      def read_fixed bytes
        value = 0
        bytes.times { value = (value << 7) | ((read_byte || invalid) & 0x7f) }
        value
      end

      #  reads one complete track from the file
      # it may set metadata in track, but the events are added to @builder!
      def read_track track, track_end
        tick = 0 # keep track of timings
        last_cmd = 0 # for running status
        #  the current file position is after the track ID and length
        while @pos < track_end
          delta_ticks = read_var or break
                                 #     tag "delta_ticks=#{delta_ticks}"
          tick += delta_ticks
          c = read_byte
          if (c & 0x80) != 0
            # have command
            cmd = c
            last_cmd = cmd if cmd < 0xf0
          else # running status
            @io.ungetbyte c
            @pos -= 1 # !!
            cmd = last_cmd
            read_error if cmd == 0
          end
          status = cmd >> 4
          channel = (cmd & 0x0f) + 1
          require_relative '../midievent'
#           tag "status=#{status}, channel=#{channel}"
          event = nil
          case status
          #  maps SMF events to ALSA sequencer events
          when 0x8
            note = read_byte & 0x7f
            off_vel = read_byte & 0x7f
            event = NoteOffEvent.new(channel, note, off_velocity: off_vel, track: track,
                                     tick: tick)
          when 0x9, 0xa #* channel msg with 2 parameter bytes */
            note = read_byte & 0x7f
            vel =  read_byte & 0x7f
            klass = status == 0x9 ? NoteOnEvent : KeypressEvent
            event = klass.new(channel, note, vel, track: track, tick: tick)
          when 0xb # controller
            param = read_byte & 0x7f
            val =  read_byte & 0x7f
            # coarse: true since ControllerEvent must interpret this value as 7 bits int.
            event = ControllerEvent.new(channel, param, val, track: track, tick: tick, coarse: true)
          when 0xc
            event =  ProgramChangeEvent.new(channel, read_byte & 0x7f, track: track,
                                            tick: tick)
          when 0xd
            event = ChannelPressureEvent.new(channel, read_byte & 0x7f, track: track,
                                             tick: tick)
          when 0xe
            event = PitchbendEvent.new(channel, read_fixed(2) - 0x2000, track: track,
                                       tick: tick)
          when 0xf
            case cmd
            when 0xf0, 0xf7 # sysex, continued sysex, or escaped commands
#               tag "sysex"
              len = read_var or read_error
              len += 1 if cmd == 0xf0
              sysex = ''
              sysex.force_encoding 'ascii-8bit'
              if cmd == 0xf0
                sysex += 0xf0.chr
                len -= 1
              end
              sysex += read(len)
              event = SysexEvent.new(sysex, track: track, tick: tick)
            when 0xff # meta event
#               tag "meta_event"
              c = read_byte
              len = read_var or read_error
              case c
              when 0x21 # port number
                read_error if len < 1
                track.portindex = read_byte
                skip(len - 1) unless len == 1
              when 0x2f # end of track
                track.end_time = tick
                event = LastEvent.new(track: track, tick: tick)
                skip(track_end - @pos) unless track_end < @pos
                @builder.<<(event, &@block)
                return
              when 0x51 # tempo
                read_error if len < 3
                if @builder.tempo.smpte_timing?
                  #  SMPTE timing doesn't change
                  skip len
                else
                  # nrof microseconds for a single beat
                  event = TempoEvent.new(0, read_int(3), track: track, tick: tick)
                  skip(len - 3) if len > 3
                end
              when 0x0 # sequence nr of the track
                invalid_format unless len == 1
                track.sequencenr = read_int(2)
              when 0x1 # description
                track.description = read(len)
              when 0x2 # copyright
                track.copyright = read(len)
              when 0x3 # name
                track.name = read(len)
              when 0x4 # voicename
                # NOTE: it is conceivable that more than one of these events can be present
                # FIXME
                tag "this probably does not work correctly"
                track.voicename = read(len)
              when 0x5 # lyrics
                # NOTE: it may be a good idea to actually create an event for this
                # since I suspect lyrics can be intertwined at certain positions
                tag "this probably does not work correctly"
                track.lyrics = read(len)
              when 0x6 # lyrics
                tag "this probably does not work correctly"
                track.marker = read(len)
              when 0x7 # cue point
                tag "this probably does not work correctly"
                track.cue_point = read(len)
              when 0x58 # time signature
                invalid_format unless len == 4
                numerator = read_byte
                denominator = read_byte
                ticks_per_beat = read_byte
                skip 1  # last byte == ????
                @builder.time_signature = numerator, denominator
                @builder.ticks_per_beat = ticks_per_beat
              when 0x59 # key signature
                invalid_format unless len == 2
                sf = read_byte # 0 == C, 1 == G, 2 == D
                # but it says -7 is B so is that 11 now ???? This is stupid
                # -128 = 0xff -127  = 0xfe
                # so -7 should be 135 up to -1 which is 128
                sf = 128 - sf if sf > 127  # and now F = -1 (at least I hope so)
                # the next byte is 0 for Major.
                @builder.key = [:C, :G, :D, :A, :E, :B, :'F#', :F, :'A#', :'D#', :'G#', :'C#'][sf],
                            read_byte == 0
              else # ignore all other meta events
                skip len
              end
            else  #  invalid Fx command
              invalid_format
            end
          else
            #  cannot happen
            invalid_format
          end
          @builder.<<(event, &@block) if event
        end # while
        # expected was EOT metaevent
        raise RRTSError.new("#{@io}: invalid MIDI data (offset=#@pos, track_end=#{track_end})")
      end

      def invalid_format
        raise RRTSError.new("#@io: invalid file format")
      end

      # reads an entire MIDI file
      def read_smf
        # the curren position is immediately after the "MThd" id
        header_len = read_int 4
        invalid_format if header_len < 6
        type = read_int 2
        if type != 0 && type != 1
          raise RRTSError.new("#@io: type #{type} format is not supported")
        end
        num_tracks = read_int 2
        unless (1..1000) === num_tracks
          raise RRTSError.new("#@io: invalid number of tracks (#{num_tracks})")
        end
        time_division = read_int 2
        #   puts "time_division=#{time_division}"
        #       /* interpret and set tempo */
        smpte_timing = (time_division & 0x8000) != 0
        require_relative '../midiqueue'
        unless smpte_timing
          # time_division is ticks per quarter
          tempo = Tempo.new 120, ticks_per_beat: time_division
        else
          tempo = Tempo.new(0x80 - ((time_division >> 8) & 0x7f), smpte_timing: true,
                                  ticks_per_frame: (time_division & 0xff))
          # upper byte is negative frames per second
          # lower byte is ticks per frame
        end
        @builder.tempo = tempo
        #   read tracks
        for i in (0...num_tracks)
          # search for MTrk chunk
          len = 0
          loop do
            id = read_id
            len = read_int
            raise RRTSError.new("#@io: invalid chunk length #{len}") if len < 0 || len >= 0x10000000
            break if id == MTRK
            skip len
          end
          require_relative 'track'
          require_relative '../midievent'
          track = Track.new
          @builder << track
          read_track(track, @pos + len)
        end
      end

      def read_riff
        # skip file length
        skip 4
        #  check file type ("RMID" = RIFF MIDI)
        invalid_format unless read_id == RMID
        #  search for "data" chunk
        loop do
          id = read_id
          len = read_32_le
          break if id == DATA
          skip((len + 1) & ~1)
        end
        #  the "data" chunk must contain data in SMF format
        invalid_format unless read_id == MTHD
        read_smf
      end
    end # class MidifileParser

=begin rdoc
    MidiIOReader is a simple node.

    [input]  IO
    [output] MidiEvents

    supported options:
    * split_tracks, default false. Only works if internalize is true.
    * combine_notes, default false (but may likely change).
      If internalize is false this will delay the emission of the Note events
      until the NoteOff is read
    * combine_progchanges, default false (but may likely change)
    * auto_close, default true. Close the stream on EOF or on errors
    * internalize, default true for files, false for pipes. Read the stream
      until EOF first, only then is the first event available.
=end
    class MidiIOReader
      private
      def initialize io, options = {}
        require_relative '../midiqueue'
        @tempo = Tempo.new
        @chunk = nil # cached if internalize is set
#         tag "options=#{options.inspect}"
        @io = io
        @split_tracks = @combine_notes = @combine_progchanges = false
        @auto_close = @internalize = true
        for k, v in options
          case k
          when :split_tracks, :combine_notes, :combine_progchanges, :auto_close,
               :internalize
            instance_variable_set(('@' + k).to_sym, v)
          else
            io.close if @auto_close
            raise RRTSError.new "illegal option '#{k}' for #{self.class}"
          end
        end
      end

=begin
This class was intended as a helper in certains cases.
But due to some design decissions in MidiEvent we alsmost must
preprocess events before they are 'recorded'.
So this class collapses two or three events to form a single new one
(or adapted).

To be specific, a MSB + LSB controller event pair (I assume the order
is always MSB first, then LSB) MUST be tied together or else TControllerEvent
will misinterpreted it.

ANOTHER FINE MESS.  Would that work?  Some obliterated device could send only
MSB's and we have a hardtime detecting such anomaly.
So this can easily be done, but not here. It requires real event storage.
=end
      class BuildHelper
        require 'forwardable'
        extend Forwardable
        private
        def initialize builder, combine_notes, combine_progchanges, &block
          @builder, @combine_notes, @combine_progchanges, @block =
            builder, combine_notes, combine_progchanges, block
          @open_notes = {} # indexed by channel:note string
          @open_prog_changes = {} # indexed by channel
        end

        def handleNoteOff event
          @on_event = @open_notes[key = "#{event.note}:#{event.channel}"]
          if @on_event
            @builder.<<(NoteEvent.new(event.channel, event.note, @on_event.velocity,
                                      track: @on_event.track,
                                      duration: event.time_diff(@on_event),
                                      off_velocity: event.velocity,
                                      time: @on_event.time), &@block)
            @open_notes.delete key
          else
            warn "DISCARDING NOTEOFF EVENT"
             # discard warning ??
          end
          self
        end

        public
        def_delegators :@builder, :tempo, :tempo=, :time_signature=, :ticks_per_beat=,
                                 :ppq=

        def << event, &block
          case event
          when NoteOnEvent
            if @combine_notes
              return handleNoteOff(event) if event.velocity == 0
              @open_notes["#{event.note}:#{event.channel}"] = event
              return self
            end
          when NoteOffEvent
            return handleNoteOff(event) if @combine_notes
          when LastEvent
            # discard ?? This could be terrible???
            warn "DISCARDING NOTEON EVENT(S)" unless @open_notes.empty?
            @open_notes = {}
            warn "DISCARDING CONTROLLER EVENT(S)" unless @open_prog_changes.empty?
            @open_prog_changes = {}
          when ControllerEvent
            case event.param
            when :bank
              @open_prog_changes[event.channel] = event
              return # !
            when :bank_lsb
              last = @open_prog_changes[event.channel]
              if last
#                 puts "LSB_BANK detected (32), last.type=#{last && last.type}, last.param=#{last && last.param}"
                if last.param == :bank
                  # replace with array
                  last.value = [last.value, event.value]
                  return
                end
              end
            end
          when ProgramChangeEvent
            last = @open_prog_changes[event.channel]
            if last
              value = Array === last.value ? last.value : [last.value]
              value << event.value
              event.value = value
              @open_prog_changes.delete(event.channel)
              # and we can forget 'last'
            end
          end
          raise StandardError.new("event #{event} has no track") if MidiEvent === event && !event.track
          @builder.<<(event, &block)
        end
      end # class BuildHelper

      public
      def each &block
        return to_enum unless block
        begin
          @chunk and return @chunk.each(&block)
          if @internalize
            require_relative 'chunk'
            builder = chunk = Chunk.new(@split_tracks)
            # since this takes time for each event better make it a special route
            if @combine_notes || @combine_progchanges
              builder = BuildHelper.new(builder, @combine_notes, @combine_progchanges, &block)
            end
            #           tag "creating MidifileParser"
            MidifileParser.new @io, builder, &block
            @chunk = chunk
            return chunk.each(&block)
          end
          if @combine_notes || @combine_progchanges
            builder = BuildHelper.new(self, @combine_notes, @combine_progchanges, &block)
          else
            builder = self
          end
          #           tag "creating MidifileParser"
          MidifileParser.new @io, builder, &block
          # Otherwise we are already done (!!) No really!
#           tag "should we send LastEvent?" But it has no track? So NO! (stupid idea)
        ensure
          @io.close if !@io.closed? && @auto_close
        end
      end

      attr_accessor :tempo

      def time_signature= bogo
      end

      def ticks_per_beat= ppq
        @tempo.ppq = ppq
      end

      alias :ppq= :ticks_per_beat=

      def << event
        yield(event) if MidiEvent === event
      end

      def rewind
        @chunk.rewind
      end
    end # class MidiIOReader

=begin rdoc
    MidiFileReader is a simple node.

    [input]  filename
    [output] MidiEvents

    See MidiIOReader

=end
    class MidiFileReader < MidiIOReader
      private
      def initialize filename, options = {}
        super File.new(filename, 'rb:ascii-8bit')
      end
    end # class MidiFileReader

=begin rdoc
    MidiPipeReader is a simple node that by default reads STDIN

    [input]  IO stream or file descriptor, if a string or array popen is used.
        Default is STDIN
    [output] MidiEvents

    See MidiIOReader

=end
    class MidiPipeReader < MidiIOReader
      private
      # Please read the docs for IO#popen and IO#open.
      def initialize io = STDIN, options = { auto_close: false }
        case io
        when String, Array
          io = IO.popen(io, 'r:ascii-8bit')
          options[:auto_close] = true
        when Integer
          io = IO.open(io, 'r:ascii-8bit')
          options[:auto_close] = true
        when IO
        else
          raise RRTSError.new("Cannot open '#{io}'")
        end
        options[:internalize] ||= false
        super
      end
    end # class MidiPipeReader

  end # Node
end # module RRTS namespace

if __FILE__ == $0
  include RRTS
  internalize = true
  r = Node::MidiPipeReader.new('cat ../../../fixtures/eurodance.midi',
                                internalize: internalize,
                                combine_notes: true, combine_progchanges: true,
                                split_tracks: true
                              )
  for e in r
    puts "e=#{e}" # inspect is insane
  end
  if internalize
    r.rewind
    # this cannot be done on above pipe since we already enumerated it.
    require 'yaml'
    File.open("./midifilereader.yaml", "w") do |file|
#       begin
        YAML.dump(r.each.to_a, file)
#       rescue StopIteration
#       end
    end
    r.rewind
    File.open("./midifilereader_sectioned.yaml", "w") do |file|
      r.each { |event| file.write event.to_yaml }
    end
  end
end