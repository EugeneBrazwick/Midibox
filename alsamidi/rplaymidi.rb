#!/usr/bin/ruby1.9.1
=begin
 * rplaymidi.rb - play Standard MIDI Files to sequencer port(s)
 * The reverse of [ar]recordmidi.*

 * Copyright (c) 2004-2006 Clemens Ladisch <clemens@ladisch.de>
 * Copyright (c) 2010 Arnoud Rattink <arnoud@rattink.com>
 * Copyright (c) 2010 Eugene Brazwick <arnoud@rattink.com>
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
 *  A copy of the GNU General Public License is located in LICENSE
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
=end

# TODO: sequencer queue timer selection

=begin
 * 31.25 kbaud, one start bit, eight data bits, two stop bits.
 * (The MIDI spec says one stop bit, but every transmitter uses two, just to be
 * sure, so we better not exceed that to avoid overflowing the output buffer.)
=end
MIDI_BYTES_PER_SEC = 31_250 / (1 + 8 + 2)

# First of all we create a parser that builds a parsetree
# aka nodetree. But in our case it just a linear Array of MidiEvents.
# With one complication: there are tracks (or parts/voices)

# My idea of a track was a single channel input.
# However it seems more that it is a complete song.
# Well that depends on the rrecordmidi param --split-channels!!
class Track
  private
  def initialize chunk_or_block
    @owner = chunk_or_block
    @events = []
    @end_tick = 0 # length of this track, in ticks
    @channel = nil # as originally recorded
    @time_signature = [4, 4] # ie 4/4
    @ticks_per_beat = 384
    @key = :C; # then :'C#', :D .... :B
    @sequencenr = 0
    @description = @copyright = @name = @voicename = @lyrics = ''
    @marker = ''
    @cue_point = ''
  end

  public
  attr_accessor :channel, :end_tick
  attr :owner, :events
  attr_accessor :time_signature, :ticks_per_beat
  attr_accessor :description, :copyright, :name, :voicename, :lyrics, :marker
  attr_accessor :cue_point
end

# Let's use 'block' for a specific timeline-part of some bars.
# Blocks can be nested and stuck together.
# While a chunk describes a piece without any internal ordering
class Soundchunk
  private
  def initialize source_port, time_division
    # MIDI files don't store this!
    @source_clientname = source_port && source_port.client.name
    @source_portname = source_port && source_port.name
    @tracks = []
    @smpte_timing = (time_division & 0x8000) != 0;
  end
  public

  def << track
    @tracks << track
  end

  attr :smpte_timing, :tracks, :source_clientname, :source_portname
end

@options = {:end_delay=>2,
#  use env var for compatibility with pmidi
            :ports=>[]
}

require 'forwardable'

# The Parser will be a class that is basically used in the chunk constructor.
# It builds a single chunk from an inputfile
class MidifileParser
  extend Forwardable
  private
  def initialize file_name, port_count, source_port
    @file_name, @port_count, @source_port = file_name, port_count, source_port
    @file = nil
  end

  def_delegator :@file, :getbyte, :read_byte

  def skip bytes
    @file.pos += bytes
     # bytes.times { read_byte }  rather crude
  end

  # reads a little-endian 32-bit integer
  def read_32_le
    # careful with expression evaluation order
    a = read_byte or return nil
    b = read_byte or invalid
    c = read_byte or invalid
    d = read_byte or invalid
    a + (b << 8) + (c << 16) + (d << 24)
  end

  # reads a 4-character identifier
  alias :read_id :read_32_le

  # reads a fixed-size big-endian number
  def read_int bytes
    value = 0
    bytes.times do
      c = read_byte or return nil
      value = (value << 8) + c
    end
    value
  end

  # reads a variable-length number, at most 4 bytes.
  # the end is indicated by the absense of bit 8 (0x80).
  # This may however be the end of the file
  def read_var
    c = read_byte or return nil  # eof
    value = c & 0x7f
    return value if (c & 0x80) == 0
    c = read_byte or invalid
    value = (value << 7) | (c & 0x7f)
    return value if (c & 0x80) == 0
    c = read_byte or invalid
    value = (value << 7) | (c & 0x7f)
    return value if (c & 0x80) == 0
    c = read_byte or invalid
    (value << 7) | c
  end

  def read_fixed bytes
    value = 0
    bytes.times do
      c = read_byte or invalid
      value = (value << 7) | (c & 0x7f)
    end
    value
  end

  # Used to create the constants below at class-parse-time
  def self.make_id c
    c[0].ord | (c[1].ord << 8) | (c[2].ord << 16) | (c[3].ord << 24)
  end

  Encoding.default_internal = 'ascii-8bit'
  MTHD = make_id('MThd')
  RIFF = make_id('RIFF')
  MTRK = make_id('MTrk')
  RMID = make_id('RMID')
  DATA = make_id('data')
  Encoding.default_internal = 'utf-8'

  def invalid
    raise RRTSError.new("#@file_name: invalid MIDI data (offset %x)" % @file.pos)
  end

  # reads one complete track (MTrk) from the file
  def read_track track, track_end
    tick = 0
    last_cmd = nil
#     fixed_channel = nil
    port = 0
    #  the current file position is after the track ID and length
    while @file.pos < track_end do
      delta_ticks = read_var or break
      tick += delta_ticks
      c = read_byte or break
      if (c & 0x80) != 0
        # have command
        cmd = c
        last_cmd = cmd if cmd < 0xf0
      else
        # running status. Take the cmd and the channel from the prev. event
        @file.ungetbyte c
        cmd = last_cmd or invalid
      end
      status = cmd >> 4
      ch = cmd & 0x0f # but not always
#       if fixed_channel
#         puts "ALERT: fixed_channel=#{fixed_channel}, ch=#{ch}" if fixed_channel != ch
#       else
#         fixed_channel = ch
#       end
      case status
      when 0x8
        value = read_byte & 0x7f
        read_byte
        event = NoteOffEvent.new ch, value
      when 0x9, 0xa
        track.channel = ch
        value = read_byte & 0x7f
        vel = read_byte & 0x7f
        event = (status == 0x9 ? NoteOnEvent : KeypressEvent).new ch, value, vel
      when 0xb
        param = read_byte & 0x7f
        value = read_byte & 0x7f
        event = ControllerEvent.new ch, param, value
      when 0xe
        event = PitchbendEvent.new ch, read_fixed(2)
      when 0xc
        event = ProgramChangeEvent.new ch, (read_byte & 0x7f)
      when 0xd
        event = ChannelPressureEvent.new ch, (read_byte & 0x7f)
      when 0xf
        case cmd
        when 0xf0, 0xf7 # sysex , 0xf7: continued sysex, or escaped commands
        len = read_var or invalid
        buf = cmd == 0xf0 ? 0xf0.chr : ''
        buf.force_encoding 'ascii-8bit'
        data = @file.read(len, buf)
        event = SysexEvent.new data
        when 0xff # meta event
          c = read_byte
          len = read_var or invalid
          case c
          when 0x21  # port number
            invalid if len < 1
            port = read_byte % @port_count
            # This is the recorded port number. See rrecordmidi.
            # But since this is basicly an internal number it is rather useless.
            # What we need is the name!!
            skip(len - 1) if len > 1
            puts "#{File.basename(__FILE__)}:#{__LINE__}:Received META event with portnr: #{port}"
          when 0x2f  # end of track
            track.end_tick = tick
            @file.pos = track_end
            return
          when 0x51 # tempo
            invalid if len < 3
            if track.owner.smpte_timing # SMPTE timing doesn't change
              skip len
            else
              a = read_byte
              b = read_byte
              c = read_byte
              queue = 0 # ???
              # this is microseconds per q.   so 120qpm => 60_000ms/120q = 500mspq
              # FIXME: I doubt TempoEvent knows anything about mspq???
              # It must be converted to what TempoEvent expects...
              # and what about the queue?
              event = TempoEvent.new queue, (a << 16) + (b << 8) + c
               # ?????
              skip(len - 3) if len > 3
            end
          when 0x0 # sequence nr of the track
            invalid unless len == 1
            track.sequencenr = read_int(2)
          when 0x1 # description
            track.description = @file.read(len)
          when 0x2 # copyright
            track.copyright = @file.read(len)
          when 0x3 # name
            track.name = @file.read(len)
          when 0x4 # voicename
            track.voicename = @file.read(len)
          when 0x5 # lyrics
            track.lyrics = @file.read(len)
          when 0x6 # lyrics
            track.marker = @file.read(len)
          when 0x7 # cue point
            track.cue_point = @file.read(len)
          when 0x58 # time signature
            invalid unless len == 4
            numerator = read_byte
            denominator = read_byte
            ticks_per_beat = read_byte
            skip 1  # last byte == ????
            track.time_signature = numerator, denominator
            track.ticks_per_beat = ticks_per_beat
          when 0x59 # key signature
            invalid unless len == 2
            sf = read_byte # 0 == C, 1 == G, 2 == D
                # but it says -7 is B so is that 11 now ???? This is stupid
                # -128 = 0xff -127  = 0xfe
                # so -7 should be 135 up to -1 which is 128
            sf = 128 - sf if sf > 127  # and now F = -1 (at least I hope so)
            # the next byte is 0 for Major.
            track.key = [:C, :G, :D, :A, :E, :B, :'F#', :F, :'A#', :'D#', :'G#', :'C#'][sf], read_byte == 0
          else # ignore all other meta events (ie 7f, sequencer specific)
            skip len
          end
        else
          invalid
        end
      else
        invalid
      end
    end
    event.port = @source_port
    event.tick = tick
  end

  # read an entire MIDI file
  def read_smf
    #    int header_len, type, time_division, i, err;
     # snd_seq_queue_tempo_t *queue_tempo;
    #  the curren position is immediately after the "MThd" id  MidiTracksHeaDer
    header_len = read_int(4)
    fail("#@file_name: invalid file format") if header_len < 6
    type = read_int 2
    # OK, See http://faydoc.tripod.com/formats/mid.htm
    # 0 == single track
    # 1 = multiple tracks. They all start at the same time.
    # 2 = multiple tracks, async. They may start at different times, using relative ticks.
    if type != 0 && type != 1
      fail "#@file_name: type #{type} format is not supported"
    end
    num_tracks = read_int 2
    unless num_tracks.between?(1, 1000)
      fail "#@file_name: invalid number of tracks (#{num_tracks})"
    end
    time_division = read_int(2) or  # the number of deltaticks per beat (q)
    # there is a problem here. The read_int will never ever return a negative number...
    # So let's put it this way:  Interesting enough it can never be more than 2*28.
      fail("#@file_name: premature end of file")
    chunk = Soundchunk.new(nil, time_division)
    # read tracks
    num_tracks.times do
      # search for MTrk chunk
      len = 0
      loop do
        id = read_id
        len = read_int 4 || fail("#@file_name: unexpected end of file when reading chunk")
        unless len.between?(0, 0x10000000 - 1)
          fail("#@file_name: invalid chunk length #{len}")
        end
        break if id == MTRK
        skip len
      end
      track = Track.new chunk
      read_track(track, @file.pos + len)
      chunk << track  # only add it when complete
    end
  end

  def read_riff
    # skip file length
    4.times { read_byte }
    #  check file type ("RMID" = RIFF MIDI)
    raise RRTSError.new("#@file_name: invalid file format") unless read_id == RMID
     # search for "data" chunk
    loop do
      id = read_id
      len = read_32_le
      if @file.eof?
        raise RRTSError.new("#@file_name: data chunk not found")
      end
      break if id == DATA
      raise RRTSError.new("#@file_name: data chunk not found") if len < 0
      skip (len + 1) & ~1
    end
    # the "data" chunk must contain data in SMF format
    raise RRTSError.new("#@file_name: invalid file format") unless read_id == MTHD
    read_smf
  end

=begin
  def part_of_play # FIXME
  # interpret and set tempo
  snd_seq_queue_tempo_alloca(&queue_tempo);
  smpte_timing = !!(time_division & 0x8000);
  if (!smpte_timing) {
        /* time_division is ticks per quarter */
       snd_seq_queue_tempo_set_tempo(queue_tempo, 500000); /* default: 120 bpm */
         snd_seq_queue_tempo_set_ppq(queue_tempo, time_division);
        } else {
                /* upper byte is negative frames per second */
               i = 0x80 - ((time_division >> 8) & 0x7f);
               /* lower byte is ticks per frame */
               time_division &= 0xff;
               /* now pretend that we have quarter-note based timing */
               switch (i) {
                           case 24:
                          snd_seq_queue_tempo_set_tempo(queue_tempo, 500000);
                          snd_seq_queue_tempo_set_ppq(queue_tempo, 12 * time_division);
                          break;
                          case 25:
                          snd_seq_queue_tempo_set_tempo(queue_tempo, 400000);
                          snd_seq_queue_tempo_set_ppq(queue_tempo, 10 * time_division);
                          break;
                          case 29: /* 30 drop-frame */
                          snd_seq_queue_tempo_set_tempo(queue_tempo, 100000000);
                          snd_seq_queue_tempo_set_ppq(queue_tempo, 2997 * time_division);
                          break;
                          case 30:
                          snd_seq_queue_tempo_set_tempo(queue_tempo, 500000);
                          snd_seq_queue_tempo_set_ppq(queue_tempo, 15 * time_division);
                          break;
                          default:
                          errormsg("%s: invalid number of SMPTE frames per second (%d)",
                           file_name, i);
                          return 0;
                          }
                                           }
  err = snd_seq_set_queue_tempo(seq, queue, queue_tempo);
  if (err < 0) {
                errormsg("Cannot set queue tempo (%u/%i)",
                         snd_seq_queue_tempo_get_tempo(queue_tempo),
                         snd_seq_queue_tempo_get_ppq(queue_tempo));
               return 0;
               }
=end


  public

  # Soundblock MidifileParser#run
  def run
    File.open(@file_name == '-' ? 0 : @file_name, "rb:binary") do |file|
      @file = file
      file_offset = 0
      id = read_id
#       puts "#{File.basename(__FILE__)}:#{__LINE__}:id=#{'%x' % id},MTHD=#{'%x' % MTHD},RIFF=#{'%x' % RIFF}"
      case
      when MTHD then read_smf
      when RIFF then read_riff
      else fail("#@file_name is not a Standard MIDI File")
      end
    end
  end
end # class MidifileParser

# plays a chunk
class Player
  private
  def initialize sequencer, ports
    @sequencer, @ports = sequencer, ports
  end
  public

  def play chunk
  end
end

require 'optparse'

opts = OptionParser.new
opts.banner = "Usage: #$PROGRAM_NAME [options] inputfile ..."
opts.on('-h', '--help', 'this help') { puts opts.to_s; exit 1 }
opts.on('-V', '--version', 'show version') { STDERR.puts "rplaymidi version 1.0"; exit }
opts.on('-l', '--list', 'list output ports') do
  puts ' Port    Client name                      Port name'
  for portname, port in @sequencer.ports
    #  port must understand MIDI messages
    if port.type?(:midi_generic) &&
    # we need both WRITE and SUBS_WRITE
                port.capability?(:write, :subscription_write)
      printf "%3d:%-3d  %-32.32s %s\n", port.client_id, port.port, port.client.name, portname
    end
  end
  exit
end
opts.on('-p', '--port=VAL', 'comma separated list of output port[s]') do |port|
  @options[:ports] = port.split(',').map { |name| @sequencer.parse_address name }
end
opts.on('-d', '--delay=VAL', 'exit delay', Integer) { |v| @options[:end_delay] = v }

require_relative 'sequencer'

include RRTS
Sequencer.new('rplaymidi') do |sequencer|
  @sequencer = sequencer  # for opts!!
  port_str = ENV['ALSA_OUTPUT_PORTS'] and
    @options[:ports] =  port_str.split(',').map { |name| sequencer.parse_address name }
  file_names = opts.parse ARGV
  fail('Please specify a file to play.') if file_names.empty?
  #  parse one or more port addresses from the string
#   puts "options=#@options"
  fail("Please specify [a] destination port[s] with --port.") if @options[:ports].empty?
  #  the first created port is 0 anyway, but let's make sure ...
  require_relative 'midiqueue'
  MidiPort.new(sequencer, 'rplaymidi', port: 0, midi_generic: true, application: true) do |source_port|
    MidiQueue.new(sequencer, 'rplaymidi') do |queue|
                                     #  the queue is now locked, which is just fine
=begin
      * We send MIDI events with explicit destination addresses, so we don't
      * need any connections to the playback ports.  But we connect to those
      * anyway to force any underlying RawMIDI ports to remain open while
      * we're playing - otherwise, ALSA would reset the port after every
      * event.
=end
      for port in @options[:ports]
        source_port.connect_to port
      end
      for file_name in file_names
        soundblock = MidifileParser.new(file_name, @options[:ports].length, source_port).run
        Player.new(sequencer, @options[:ports]).play soundblock
      end
    end
  end
end

__END__

# build ev from event ?
static void handle_big_sysex(snd_seq_event_t *ev)
{
	unsigned int length;
	ssize_t event_size;
	int err;

	length = ev->data.ext.len;
	if (length > MIDI_BYTES_PER_SEC)
		ev->data.ext.len = MIDI_BYTES_PER_SEC;
	event_size = snd_seq_event_length(ev);
	if (event_size + 1 > snd_seq_get_output_buffer_size(seq)) {
		err = snd_seq_drain_output(seq);
		check_snd("drain output", err);
		err = snd_seq_set_output_buffer_size(seq, event_size + 1);
		check_snd("set output buffer size", err);
	}
	while (length > MIDI_BYTES_PER_SEC) {
		err = snd_seq_event_output(seq, ev);
		check_snd("output event", err);
		err = snd_seq_drain_output(seq);
		check_snd("drain output", err);
		err = snd_seq_sync_output_queue(seq);
		check_snd("sync output", err);
		if (sleep(1))
			fatal("aborted");
		ev->data.ext.ptr += MIDI_BYTES_PER_SEC;
		length -= MIDI_BYTES_PER_SEC;
	}
	ev->data.ext.len = length;
}

static void play_midi(void)
{
	snd_seq_event_t ev;
	int i, max_tick, err;

	/* calculate length of the entire file */
	max_tick = -1;
	for (i = 0; i < num_tracks; ++i) {
		if (tracks[i].end_tick > max_tick)
			max_tick = tracks[i].end_tick;
	}

	/* initialize current position in each track */
	for (i = 0; i < num_tracks; ++i)
		tracks[i].current_event = tracks[i].first_event;

	/* common settings for all our events */
	snd_seq_ev_clear(&ev);
	ev.queue = queue;
	ev.source.port = 0;
	ev.flags = SND_SEQ_TIME_STAMP_TICK;

	err = snd_seq_start_queue(seq, queue, NULL);
	check_snd("start queue", err);
	/* The queue won't be started until the START_QUEUE event is
	 * actually drained to the kernel, which is exactly what we want. */

	for (;;) {
		struct event* event = NULL;
		struct track* event_track = NULL;
		int i, min_tick = max_tick + 1;

		/* search next event */
		for (i = 0; i < num_tracks; ++i) {
			struct track *track = &tracks[i];
			struct event *e2 = track->current_event;
			if (e2 && e2->tick < min_tick) {
				min_tick = e2->tick;
				event = e2;
				event_track = track;
			}
		}
		if (!event)
			break; /* end of song reached */

		/* advance pointer to next event */
		event_track->current_event = event->next;

		/* output the event */
		ev.type = event->type;
		ev.time.tick = event->tick;
		ev.dest = ports[event->port];
		switch (ev.type) {
		case SND_SEQ_EVENT_NOTEON:
		case SND_SEQ_EVENT_NOTEOFF:
		case SND_SEQ_EVENT_KEYPRESS:
			snd_seq_ev_set_fixed(&ev);
			ev.data.note.channel = event->data.d[0];
			ev.data.note.note = event->data.d[1];
			ev.data.note.velocity = event->data.d[2];
			break;
		case SND_SEQ_EVENT_CONTROLLER:
			snd_seq_ev_set_fixed(&ev);
			ev.data.control.channel = event->data.d[0];
			ev.data.control.param = event->data.d[1];
			ev.data.control.value = event->data.d[2];
			break;
		case SND_SEQ_EVENT_PGMCHANGE:
		case SND_SEQ_EVENT_CHANPRESS:
			snd_seq_ev_set_fixed(&ev);
			ev.data.control.channel = event->data.d[0];
			ev.data.control.value = event->data.d[1];
			break;
		case SND_SEQ_EVENT_PITCHBEND:
			snd_seq_ev_set_fixed(&ev);
			ev.data.control.channel = event->data.d[0];
			ev.data.control.value =
				((event->data.d[1]) |
				 ((event->data.d[2]) << 7)) - 0x2000;
			break;
		case SND_SEQ_EVENT_SYSEX:
			snd_seq_ev_set_variable(&ev, event->data.length,
						event->sysex);
			handle_big_sysex(&ev);
			break;
		case SND_SEQ_EVENT_TEMPO:
			snd_seq_ev_set_fixed(&ev);
			ev.dest.client = SND_SEQ_CLIENT_SYSTEM;
			ev.dest.port = SND_SEQ_PORT_SYSTEM_TIMER;
			ev.data.queue.queue = queue;
			ev.data.queue.param.value = event->data.tempo;
			break;
		default:
			fatal("Invalid event type %d!", ev.type);
		}

		/* this blocks when the output pool has been filled */
		err = snd_seq_event_output(seq, &ev);
		check_snd("output event", err);
	}

	/* schedule queue stop at end of song */
	snd_seq_ev_set_fixed(&ev);
	ev.type = SND_SEQ_EVENT_STOP;
	ev.time.tick = max_tick;
	ev.dest.client = SND_SEQ_CLIENT_SYSTEM;
	ev.dest.port = SND_SEQ_PORT_SYSTEM_TIMER;
	ev.data.queue.queue = queue;
	err = snd_seq_event_output(seq, &ev);
	check_snd("output event", err);

	/* make sure that the sequencer sees all our events */
	err = snd_seq_drain_output(seq);
	check_snd("drain output", err);

	/*
	 * There are three possibilities how to wait until all events have
	 * been played:
	 * 1) send an event back to us (like pmidi does), and wait for it;
	 * 2) wait for the EVENT_STOP notification for our queue which is sent
	 *    by the system timer port (this would require a subscription);
	 * 3) wait until the output pool is empty.
	 * The last is the simplest.
	 */
	err = snd_seq_sync_output_queue(seq);
	check_snd("sync output", err);

	/* give the last notes time to die away */
	if (end_delay > 0)
		sleep(end_delay);
}

