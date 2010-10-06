#!/usr/bin/ruby -w
# The reverse of midifilereader
module RRTS #namespace

  module Node

    require 'rrts/rrts'
    require 'rrts/node/node'

=begin
    100% the reverse of the MidifileParser.
    There are two cases.
    1) the easy one.  Our input is a Chunk. Read the chunk, dump the data
    2) the difficult one.  Our input is a Producer or a Filter in which case
    we end up in
      consume

=end

        # The writer serves as a sink.
    class MidiIOWriter < Consumer
    private

=begin
  Create a new MidiIOWriter that will write to io, reading from producer.
=end
      def initialize io, producer = nil
        super(producer)
        @io = io
        @last_command = 0 # for 'running status'
      end

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

      # writes a fixed-size big-endian number
      def write_int value, bytes = 4
#         tag "write_int #{value}, using #{bytes} bytes at pos #{@io.pos} : [#{value >> 24},#{(value >> 16) & 0xff},#{(value >> 8) & 0xff},#{value & 0xff}]"
        @io.putc(value >> 24) if bytes == 4
        @io.putc((value >> 16) & 0xff) if bytes >= 3
        @io.putc((value >> 8) & 0xff) if bytes >= 2
        @io.putc(value & 0xff)
      end

      def write_32_le v
        @io.putc(v & 0xff)
        @io.putc((v >> 8) & 0xff)
        @io.putc((v >> 16) & 0xff)
        @io.putc(v >> 24)
      end

      alias :write_id :write_32_le

      POW2_28 = 1 << 28
      POW2_21 = 1 << 21
      POW2_14 = 1 << 14
      POW2_7 = 1 << 7

      # write variable length integer using bit 8. Returns v for convience.
      def write_var v
        @io.putc(0x80 | ((v >> 28) & 0x03)) if v >= POW2_28
        @io.putc(0x80 | ((v >> 21) & 0x7f)) if v >= POW2_21
        @io.putc(0x80 | ((v >> 14) & 0x7f)) if v >= POW2_14
        @io.putc(0x80 | ((v >> 7) & 0x7f)) if v >= POW2_7
        @io.putc(v & 0x7f)
        v
      end

      # write command. Can be skipped if equal to last_command
      def write_command command
#         tag "write_command pos=#{@io.pos}, #{command}, last_command = #@last_command"
        @io.putc(command) if command != @last_command
        @last_command = command < 0xf0 ? command : 0
      end

      # NoteEvents are waiting and should release a NoteOffEvent if this is just
      # before 'eventtm'.
      # so note.time + note.duration < eventtm!
      def handle_notes_to_close track, notes_to_close, eventtm
#         tag "notes_to_close, offtimes=#{notes_to_close.map{|n|n.time+n.duration}.inspect}, tick=#@tick,eventtm=#{eventtm}"
        notes_to_close.each_with_index do |note, i|
          off_time = note.time + note.duration
#           tag "handle_notes_to_close, compare notetm #{off_time} with eventtm #{eventtm}, tick=#@tick"
#           next if note > event  ALWAYS
          next if off_time > eventtm
          delta_ticks = off_time - @tick
          raise RRTSError.new("Really, an invalid timestamp....") if delta_ticks < 0
          @tick += write_var(delta_ticks)
          status = 0x8
          write_command((0x8 << 4) + note.channel - 1)
          @io.putc note.note
          @io.putc note.off_velocity
          notes_to_close[i] = nil
        end
        notes_to_close.delete(nil)
      end

      def write_event track, event, notes_to_close
         # this only works if events are recorded in ticks!  FIXME
#         tag "write_event, at pos #{@io.pos}"
        if (delta_ticks = event.time - @tick) < 0
          raise RRTSError, "Invalid delta #{delta_ticks} in source, tick = #@tick, " +
                           "event.time=#{event.time.inspect}\nevent=#{event}"
        end
#         tag "writing delta #{delta_ticks} at pos #{@io.pos}, tick:=#{@tick + delta_ticks}"
        status = event.status
        ch = event.channel ? event.channel - 1 : 0
        command = (status << 4) + ch
#         tag "status = #{status}, ch = #{ch}, event.class=#{event.class}, command=#{command}, pos = #{@io.pos}"
        case event
        when NoteOnEvent, NoteOffEvent, KeyPressEvent
#           tag "NoteO[n|ff]Event, KeyPressEvent"
          @tick += write_var(delta_ticks)
          write_command(command)
          @io.putc event.note
          @io.putc event.velocity
        when NoteEvent
          @tick += write_var(delta_ticks)
          write_command((0x9 << 4) + ch)
          @io.putc event.note
          @io.putc event.velocity
          notes_to_close << event.dup
          notes_to_close.sort!{|n, o| n.off_time <=> o.off_time }
        when ControllerEvent
          @tick += write_var(delta_ticks)
          write_command(command)
#           tag "Controller event on channel #{ch}"
          param = event.param
          param = MidiEvent::Symbol2Param[param] if Symbol === param
#           tag "store param #{param} for #{event.param} at pos #{@io.pos}"
          lsb = MidiEvent::Symbol2Param[event.msb2lsb]
          @io.putc(param)
          if Array === event.value   # tuple MSB+LSB
            # Control14
            @io.putc(event.value[0] & 0x7f)
            @io.putc(0) # delta
#             tag "running state at pos #{@io.pos}"
            @io.putc(lsb)
            @io.putc(event.value[1] & 0x7f)
          elsif lsb && !event.flag(:coarse)
            # Control14
            @io.putc((event.value >> 7) & 0x7f)
            @io.putc(0) # delta
#             tag "running state at pos #{@io.pos}"
            @io.putc(lsb)
            @io.putc(event.value & 0x7f)
          else
            event.value = ControllerEvent::ON if event.value == true
            event.value = ControllerEvent::OFF if event.value == false
            @io.putc(event.value & 0x7f)
          end
        when ProgramChangeEvent
          @tick += write_var(delta_ticks)
          #           tag "ProgramChangeEvent"
          # could be prog or [bank14, prog] or [bankmsb,lsb,prog] or [bank7,prog] and flag(:coarse)
          if Array === event.value
#             tag "Emit ControllerEvent first!"
            write_command((0xb << 4) + ch)
            @io.putc(Driver::MIDI_CTL_MSB_BANK)
            if event.value.length == 3
              @io.putc(event.value[0])
              @io.putc(0) # delta
#               tag "produce running state at pos #{@io.pos}"
              @io.putc(Driver::MIDI_CTL_LSB_BANK)
              @io.putc(event.value[1])
              program = event.value[2]
            elsif event.flag(:coarse)
              @io.putc(event.value[0]) # MSB value
              program = event.value[1]
            else
              @io.putc(event.value[0] >> 7) # MSB value
              @io.putc(0) # delta
#               tag "produce running state at pos #{@io.pos}, putc#{Driver::MIDI_CTL_LSB_BANK}, value[0]=#{event.value[0]}"
              @io.putc(Driver::MIDI_CTL_LSB_BANK)
              @io.putc(event.value[0] & 0x7f)
              program = event.value[1]
            end
            @io.putc(0) # delta
          else
            program = event.value
          end
#           tag "write progchange command at pos #{@io.pos}"
          write_command(command)
#           tag "program=#{program.inspect}"
          @io.putc(program & 0x7f)
        when ChannelPressureEvent
          @tick += write_var(delta_ticks)
          write_command(command)
          @io.putc(event.value & 0x7f)
        when PitchBendEvent
          @tick += write_var(delta_ticks)
          write_command(command)
          value = event.value + 0x2000
          @io.putc(value & 0x7f)
          @io.putc((value >> 7) & 0x7f)
        when SysexEvent
          @tick += write_var(delta_ticks)
          # note arecordmidi.c  IGNORES this if len is 0.
          # But I already sent the delta. Why would there be 0 length events anyway?
          sysex = event.value # should be ascii-8bit encoding
          if sysex[0] == 0xf0.chr
            write_command(0xf0)
            i = 1
          else
            write_command(0xff)
            i = 0
          end
          write_var sysex.length - i
          @io.write(sysex[i..-1])
        when TempoEvent
#           tag "Writing tempo event 0xff 0x51 0x03 #{event.value}in 3 bytes"
          @tick += write_var(delta_ticks)
          @io.putc(0xff) # meta
          @io.putc(0x51) # tempo
          @io.putc(0x03) # len = 3
          write_int event.value, 3
        when LastEvent
          @tick += write_var(delta_ticks)
          @io.putc(0xff) # meta
          @io.putc(0x2f) # EOT
          write_var 0 # len !!
        when TimeSignatureEvent
#           tag "Writing TimeSignatureEvent at pos #{@io.pos} delta 0xff 0x58 0x04 #{event.num} #{event.denom} #{event.clocks_per_beat} 0"
          @tick += write_var(delta_ticks)
          @io.putc(0xff)
          @io.putc(0x58) # time sig
          @io.putc(0x04) #write_var 4 # length of meta
          @io.putc event.num
          @io.putc event.denom
          @io.putc event.clocks_per_beat
          @io.putc event.something  # 32s per 24 clocks  Unclear....
        when KeySignatureEvent
          write_var 0  # delta
          @io.putc(0xff)
          @io.putc(0x59)
          @io.putc(0x02) # write_var 2 # length of meta
          @io.putc MapKey2Byte[event.key]
          @io.putc(if event.major? then 1 else 0 end)
        else
          todo "else, event=#{event}"
        end
      end

      def write_meta_string text, metabyte
        return unless text
#         tag "write meta #{text} at pos #{@io.pos}"
        write_var 0  # delta
        @io.putc(0xff)
        @io.putc metabyte
        write_var text.length
        @io.write(text)
      end

      MapKey2Byte = {:C=>0, :G=>1, :D=>2, :A=>3, :E=>4, :B=>5, :'F#'=>6, :'C#'=>7,
                     :F=>-1, :'Bb'=>-2, :'Eb'=>-3, :'Ab'=>-4, :'Db'=>-5, :'Gb'=>-6, :'Cb'=>-7
                    }
      def write_track track
#         tag "write_track #{track}, pos=#{@io.pos}"
        write_id MTRK
        memposlen = @io.pos
        write_int 0 # dummy for position
        @tick = 0
        @last_command = 0
        notes_to_close = []
        # dump the track metas
        if track.sequencenr
#           tag "write seqnr at pos #{@io.pos}"
          write_var 0  # delta
          @io.putc(0xff)
          @io.putc(0x0)
          write_var 2  # length
          write_int track.sequencenr, 2
        end
        if track.portindex
#           tag "write portindex at pos #{@io.pos}"
          write_var 0  # delta
          @io.putc(0xff)
          @io.putc(0x21)
          write_var 1
          @io.putc(track.portindex)
        end
        write_meta_string track.copyright, 0x2
        write_meta_string track.name, 0x3
        write_meta_string track.intended_device, 0x9
#         tag "after meta's pos = #{@io.pos}"
        for event in track
#           tag "put event #{event.class} in track at pos #{@io.pos}"
          raise RRTSError.new("Can't record MIDI file from realtime events") unless Integer === event.time
#           tag "event.time=#{event.time}"
          handle_notes_to_close(track, notes_to_close, event.time) unless notes_to_close.empty?
#           tag "after notes to close.... pos = #{@io.pos}"
          write_event track, event, notes_to_close
        end
        sz = @io.pos - memposlen - 4 # substract 4 extra bytes for the length itself
#         tag "pos=#{@io.pos}, memposlen=#{memposlen}, -> sz = #{sz}"
        p = @io.pos
        @io.pos = memposlen
        write_int sz
        @io.pos = p
      end

      def write_smf chunk
        raise RRTSError, 'chunk has no track' unless chunk.track
        header_len = 6 # type(2) + numtracks(2) + time_division(2)
        write_int header_len
        tempo = chunk.tempo
#         tag "tempo=#{tempo.inspect}, chunk=#{chunk.inspect}"
        tracks = chunk.listing
        type = tracks.length > 1 ? 1 : 0
        write_int type, 2
        write_int tracks.length, 2
        write_int tempo.time_division, 2
        # there would be room for Midibox specific stuff
        tracks.each { |track| write_track(track) }
      end

      def dump chunk
        write_id MTHD
        write_smf chunk
      ensure
        @io.close
      end

   public
      # Dump the events to @io, using the Midi file format
      def consume producer
#         tag "kludge alert"
        # this is a kludge.  The MIDI format is not necessarily streamable
        # Not the events are written, but the tracks.
        # if there is only one track it wouldn't matter, but let's create a more
        # general solution.  Just create a Chunk and dump that.
        if chunk = producer.to_chunk
          dump chunk
          nil
        else
#           tag "creating chunk then"
          require_relative 'chunk'
          chunk = Chunk.new
          # the options for the chunk should be supplied by producer.
          # now create a fiber for the chunk and return that.
#           tag "forward 'consume' call:"
          chunk.consume producer do
            # after loading, do this:
            raise RRTSError, 'Corrupted chunk, has no track' unless chunk.track
            dump chunk
            # plus the original exitcode as passed to this consume
            yield if block_given?
          end
        end
      end

    end # class MidiIOWriter

    # Convenience class for dump to named file
    class MidiFileWriter < MidiIOWriter
      private
      # See MidiIOWriter. The file is automatically closed when done.
      def initialize filename, producer = nil
        super(File.new(filename, 'wb:ascii-8bit'), producer)
      end
    end # class MidiFileWriter
  end # Node
end # RRTS

if __FILE__ == $0
  include RRTS
  include Node
  require_relative 'midifilereader'
  input = MidiFileReader.new('../../../fixtures/eurodance.midi', spam: true)
  MidiFileWriter.new('/tmp/eurodance.midi', input)
  MidiFileReader.new('/tmp/eurodance.midi', spam: true)
end

