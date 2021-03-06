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

    require 'rrts/rrts'
    require 'rrts/node/node'

#   The MidiIOReader is a Producer that creates MidiEvents from a MIDI file
#   (Standard Midi Fileformat)
#
#   It does this by creating events.
#
#   Normally you would connect it to a chunk node.
#
#   ----
#
#   The port indices as read from the MIDI file remain as is within the tracks.
#   Each event build will contain a track reference so this portindex can then be
#   used by the consumer.  Note that is NOT a port id, but an indication of a portindex.
#   For example if the recorder used three inputports then the indices 0, 1 and 2
#   are used. But the player may not even have three ports available, and even if so,
#   they may refer to different devices than what was recorded.
#
# This class is a Producer, and therefore includes Enumerable. You can read the events
# simply by using +each+.
# MidiIOReader will obey write_ahead and the ticktimes in the MIDI file. Hence it will
# play the recording in about the recorded time.
# If you just want to read the tracks you must pass the +spam+ option to the constructor,
# so that the output is created as fast as possible.
    class MidiIOReader < Producer
      private

        def parse_option k, v
          case k
          when :auto_close then @auto_close = v
          when :split_channels then @split_channels = v
          when :combine_notes then @combine_notes = v
          when :combine_progchanges then @combine_progchanges = v
          when :combine_lsb_msb then @combine_lsb_msb = v
          when :no_tampering then @combine_lsb_msb = @combine_notes = @combine_progchanges =
                                  @split_channels = !v
          else super
          end
        end

#     Parameters:
#     [io]  IO to read from
#     [options] supported are:
#       [:split_tracks] default false. Create separate tracks
#       [:combine_notes] default true.
#                        This will delay the emission of the Note events until the NoteOff is read
#       [:combine_progchanges] default true. Combine bank + progchange messages.
#       [:combine_lsb_msb] default true. Combine control14 messages
#       [:auto_close] default true. Close the stream on EOF or on errors
#       [:no_tampering] setting it to true sets split_channels, combine_progchanges, combine_notes,
#                       and combine_lsb_msb to the opposite of the value passed here (normally 'true')
#
#     *IMPORTANT*  these combine + split options do not do anything here at all. They are
#     however stored in the ChunkCreateEvent, which is actually the first event.
#     Consider them hints to the processor of these events.
        def initialize io, options = {}
          require_relative '../tempo'
          @io = io # what we read from
          @pos = 0 # io.pos does not work on pipes. So there...
          @split_channels = false
          @combine_lsb_msb = @combine_notes = @combine_progchanges = true
          @auto_close = true
          super(options)
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

        def read_error what
          raise RRTSError.new("#@io: invalid MIDI data (offset #{@pos}): #{what}")
        end

        #  reads one complete track from the file
        # it may set metadata in track, but the events are added to @builder!
        # there MUST be a current track or this information is lost for those that
        # do not make the chunk !
        def read_track track_key, track_end
          tick = 0 # keep track of timings
          last_cmd = 0 # for running status
  #         tag "read_track, starting at pos #@pos, last_cmd := 0, track_end = #{track_end}"
          meta_channel = 0
          #  the current file position is after the track ID and length
          while @pos < track_end
  #           tag "pos = #@pos, track_end = #{track_end}"
            delta_ticks = read_var or break
  #           tag "delta_ticks=#{delta_ticks}, pos of command is #@pos"
            tick += delta_ticks
            c = read_byte
            if (c & 0x80) != 0
              # have command
              cmd = c
              last_cmd = cmd if cmd < 0xf0
  #             tag "read c #{c}, last_cmd = #{last_cmd}, pos=#@pos"
            else # running status, should not have read 'c' then
              @io.ungetbyte c
              @pos -= 1 # !!
  #             tag "got byte #{c}, not a status, using recorded last_cmd: #{last_cmd}"
              cmd = last_cmd
              read_error("running status was 0, last byte read was #{c}") if cmd == 0
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
              event = NoteOffEvent.new(channel, note, off_velocity: off_vel)
            when 0x9, 0xa #* channel msg with 2 parameter bytes */
              note = read_byte & 0x7f
              vel =  read_byte & 0x7f
              klass = status == 0x9 ? NoteOnEvent : KeypressEvent
              event = klass.new(channel, note, vel)
            when 0xb # controller
              param = read_byte & 0x7f
              val =  read_byte & 0x7f
              # coarse: true since ControllerEvent must interpret this value as 7 bits int.
              event = ControllerEvent.new(channel, param, val, coarse: true)
            when 0xc
              event =  ProgramChangeEvent.new(channel, read_byte & 0x7f)
            when 0xd
              event = ChannelPressureEvent.new(channel, read_byte & 0x7f)
            when 0xe
              a = read_byte & 0x7f  # lo
              b = read_byte & 0x7f  # hi
              event = PitchbendEvent.new(channel, a + b << 7 - 0x2000)
            when 0xf
              case cmd
              when 0xf0, 0xf7 # sysex, continued sysex, or escaped commands
  #               tag "sysex"
                len = read_var or read_error('could not read length')
                len += 1 if cmd == 0xf0
                sysex = ''
                sysex.force_encoding 'ascii-8bit'
                if cmd == 0xf0
                  sysex += 0xf0.chr
                  len -= 1
                end
                sysex += read(len)
                event = SysexEvent.new(sysex)
              when 0xff # meta event
                c = read_byte
  #               tag "read byte #{c} == meta event kind, pos = #@pos"
                len = read_var or read_error('could not read metalength')
  #               tag "read meta_event #{c}, len = #{len}, pos = #@pos"
                case c
                when 0x21 # port number
                  read_error('0 length portnumber') if len < 1
                  event = TrackPortIndexEvent.new(read_byte)
                  skip(len - 1) unless len == 1
                when 0x2f # end of track
                  event = LastEvent.new
                  skip(track_end - @pos) unless track_end < @pos
                when 0x51 # tempo
  #                 tag "got tempo, len = #{len}"
                  read_error('tempo too short') if len < 3
                  if @tempo.smpte_timing?
                    #  SMPTE timing doesn't change
                    skip len
                  else
                    # nrof microseconds for a single beat
                    event = TempoEvent.new(0, read_int(3))
                    skip(len - 3) if len > 3
                  end
                when 0x0 # sequence nr of the track
                  invalid_format('sequencenr must be 2 long') unless len == 2
                  track.sequencenr = read_int(2)
                when 0x1 # description, comments.
                  event = CommentEvent.new(read(len))
                when 0x2 # copyright
                  track.copyright = read(len)
                when 0x3 # name
                  track.name = read(len)
                when 0x4 # voicename
                  # should be prefixed with MetaChannelEvent
                  event = VoiceNameEvent.new(meta_channel, read(len))
                when 0x5 # lyrics
                  #   AHA http://www.midi.org/techspecs/rp17.php
                  event = LyricsEvent.new(read(len))
                  # See http://www.midi.org/techspecs/rp26.php  for abuse of lyrics
                  # to set the composer, songname etc..
                  # {@LATIN}
                  # {#Composer=Eugene Brazwick}
                  # Should be set at tick 0.
                when 0x6 # marker
                  event = MarkerEvent.new(read(len))
                when 0x7 # cue point
                  event = CuePointEvent.new(read(len))
                when 0x8 # program name. Must be immediately followed by Bank + ProgChange
                  # should be prefixed with MetaChannelEvent
                  event = ProgramNameEvent.new(meta_channel, read(len))
                when 0x9 # intended device
                  event = TrackIntendedDeviceEvent.new(read(len))
                when 0x20
                  meta_channel = read_byte
                when 0x58 # time signature
  #                 tag "read time signature (4 bytes), pos = #@pos, len = #{len}"
                  invalid_format('time signature must be 4 long') unless len == 4
                  numerator = read_byte
                  denominator = read_byte
                  clocks_per_beat = read_byte
                  something = read_byte
#                   skip 1  # last byte == ???? number of 32's in a MIDI beat (== 24 clocks)
                  event = TimeSignatureEvent.new numerator, denominator, clocks_per_beat, something
  #                 @builder.time_signature = numerator, denominator
  #                 @builder.clocks_per_beat = clocks_per_beat # normally 24
  #                 tag "setup time_sig #{numerator}/#{denominator} tpb=#{clocks_per_beat}, pos is now #@pos"
                when 0x59 # key signature
                  invalid_format('key signature must be 2 long') unless len == 2
                  sf = read_byte # 0 == C, 1 == G, 2 == D (##)
                  invalid_format("Invalid signature #{sf}, range = -7..7") unless (-7..7) === sf
                  # and it says -7 is B   bbbbbbb = B
                  # the next byte is 0 for Major.
                  # and C# == Db and F# == Gb and B == Cb
                  if sf >= 0
                    key = [:C, :G, :D, :A, :E, :B, :'F#', :'C#'][sf]
                  else
                    key = [:F, :'Bb', :'Eb', :'Ab', :'Db', :'Gb', :'Cb'][-sf - 1]
                  end
  #                 @builder.key = key, (read_byte == 0)
                  event =  KeySignatureEvent.new(key, (read_byte == 0))
                else # ignore all other meta events
                  skip len
                end
              else  #  invalid Fx command
                invalid_format
              end
            else
              #  cannot happen
              invalid_format("Invalid command #{cmd}")
            end
  #           tag "sending event #{event} to builder, time=#{event && event.time.inspect}"
            if event
              event.track = track_key
              event.tick = tick
              @yielder.call(event)
              return if LastEvent === event
            end
          end # while
          # expected was EOT metaevent
          raise RRTSError.new("#{@io}: invalid MIDI data (offset=#@pos, track_end=#{track_end})")
        end

        def invalid_format what = ''
          raise RRTSError.new("#@io: invalid file format: #{what}")
        end

        # reads an entire Standard MIDI File
        def read_smf
          # the curren position is immediately after the "MThd" id
          require_relative '../midievent'
          track_options = { split_channels: @split_channels,
                            combine_lsb_msb: @combine_lsb_msb,
                            combine_notes: @combine_notes,
                            combine_progchanges: @combine_progchanges}
          ev = ChunkCreateEvent.new(track_options)
          @yielder.call(ev)
          header_len = read_int 4
          invalid_format("header_len=#{header_len} < 6") if header_len < 6
          type = read_int 2
          # 0 == 16 channels in 1 track. Only 1 track present.
          # 1 == more than one track, each track 1 channel.
          # 2 = more than one track, all tracks are separate pieces
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
          require_relative '../tempo'
          unless smpte_timing
            # time_division is ticks per quarter
            @tempo = Tempo.new 120, ticks_per_beat: time_division
          else
            @tempo = Tempo.new(0x80 - ((time_division >> 8) & 0x7f), smpte_timing: true,
                                    ticks_per_frame: (time_division & 0xff))
            # upper byte is negative frames per second
            # lower byte is ticks per frame
          end
          @yielder.call TempoEvent.new(0, @tempo)
          #   read tracks
          for i in (0...num_tracks)
            # search for MTrk chunk
            len = 0
            loop do
              id = read_id
              len = read_int
              raise RRTSError.new("#@io: invalid track length #{len}") if len < 0 || len >= 0x10000000
              break if id == MTRK
              skip len
            end
            require_relative 'track'
            ev = TrackCreateEvent.new
            @yielder.call(ev)
            read_track(ev.key, @pos + len)
          end
        end

        # this will call read_smf
        def read_riff
          # skip file length
          skip 4
          #  check file type ("RMID" = RIFF MIDI)
          invalid_format("RMID expected") unless read_id == RMID
          #  search for "data" chunk
          loop do
            id = read_id
            len = read_32_le
            break if id == DATA
            skip((len + 1) & ~1)
          end
          #  the "data" chunk must contain data in SMF format
          invalid_format('MTHD expected') unless read_id == MTHD
          read_smf
        end

      public

        # enumerate the loaded events
        def each &block
  #         return (@chunk ? @chunk.to_enum : to_enum) unless block
          return to_enum unless block
          begin
            @yielder = block
            case read_id # .tap {|v| tag "v=#{v}, MTHD=#{MTHD},RIFF=#{RIFF}"}
            when MTHD
              read_smf
            when RIFF
              read_riff # which also calls read_smf
            else
              raise RRTSError.new("#@io is not a Standard MIDI File")
            end
          ensure
            @io.close if !@io.closed? && @auto_close
          end
        end

        def split_channels?
          @split_channels
        end

    end # class MidiIOReader

#     MidiFileReader is a simple node.
#     See MidiIOReader
    class MidiFileReader < MidiIOReader
      private
      # Open and read the file. See MidiIOReader
      # The file is automatically closed when done
      def initialize filename, options = {}
        super(File.new(filename, 'rb:ascii-8bit'), options)
      end
    end # class MidiFileReader

#     MidiPipeReader is a simple node that by default reads STDIN
#     See MidiIOReader
    class MidiPipeReader < MidiIOReader
      private
      # Please read the docs for IO#popen and IO#open.
      # Can open fd, or a process
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
        super
      end
    end # class MidiPipeReader

  end # Node
end # module RRTS namespace

if __FILE__ == $0
  include RRTS
  include Node
  internalize = true
  r = MidiPipeReader.new('cat ' + File.dirname(__FILE__) + '/../../../fixtures/eurodance.midi')
  for e in r
    puts "e=#{e}" # inspect is insane
  end
  # at this point the pipe is exhausted, so we must create a new pipe.
  if internalize
    r = MidiPipeReader.new('cat ' + File.dirname(__FILE__) + '/../../../fixtures/eurodance.midi',
                           combine_notes: true, combine_progchanges: true,
                           split_channels: true)
    chunk = Chunk.new
#   r.rewind
    # this cannot be done on above pipe since we already enumerated it.
    require 'yaml'
    File.open("/tmp/midifilereader.yaml", "w") do |file|
#       begin
        YAML.dump(r.each.to_a, file)
#       rescue StopIteration
#       end
    end
    r.rewind
    File.open("/tmp/midifilereader_sectioned.yaml", "w") do |file|
      r.each { |event| file.write event.to_yaml }
    end
  end
  p = Peekable.new(MidiPipeReader.new('cat ' + File.dirname(__FILE__) + '/../../../fixtures/eurodance.midi'))
  puts "p.peek = #{p.peek}"
  puts "p.peek = #{p.peek}"
  puts "p.next = #{p.next}"
  puts "p.next = #{p.peek}"
  puts "p.peek = #{p.peek}"
  loop do
    p.next
  end
end