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

class Track
  private
  def initialize
    @events = []
    @end_tick = 0 # length of this track, in ticks
  end
end

class Soundblock
  private
  def initialize
    @tracks = []
    @smpte_timing = false
  end
end

@options = {:end_delay=>2,
#  use env var for compatibility with pmidi
            :ports=>[]
}

require 'forwardable'

class MidifileParser
  extend Forwardable
  private
  def initialize file_name, port_count, source_port
    @file_name, @port_count, @source_port = file_name, port_count, source_port
    @file = nil
  end

  def_delegator :@file, :read_byte, :getbyte

  def skip bytes
    bytes.times { read_byte }
  end

  # reads a little-endian 32-bit integer
  def read_32_le
    # careful with expression evaluation order
    a = read_byte or return nil
    b = read_byte or return nil
    c = read_byte or return nil
    d = read_byte or return nil
    a + (b << 8) + (c << 16) + (d << 24)
  end

  # reads a 4-character identifier
  alias :read_id :read_32_le

  # reads a fixed-size big-endian number
  def read_int bytes
    value = 0
    bytes.timed do
      c = read_byte or return nil
      value = (value << 8) + c
    end
    value
  end

  # reads a variable-length number
  def read_var
    c = read_byte or return nil
    value = c & 0x7f
    return value if (c & 0x80) == 0
    c = read_byte or return nil
    value = (value << 7) | (c & 0x7f)
    return value if (c & 0x80) == 0
    c = read_byte or return nil
    value = (value << 7) | (c & 0x7f)
    return value if (c & 0x80) == 0
    c = read_byte or return nil
    (value << 7) | c
  end

  def read_fixed bytes
    value = 0
    bytes.times do
      c = read_byte or return nil
      value = (value << 7) | (c & 0x7f)
    end
    value
  end

  def self.make_id c
    c[0].ord | (c[1].ord << 8) | (c[2].ord << 16) | (c[3].ord << 24)
  end

  Encoding.default_internal = 'ascii-8bit'
  MTHD = make_id('Mthd')
  RIFF = make_id('RIFF')
  MTRK = make_id('MTrk')
  RMID = make_id('RMID')
  DATA = make_id('data')
  Encoding.default_internal = 'utf-8'

  def invalid
    raise RRTSError.new("#@file_name: invalid MIDI data (offset %x)" % @file.pos)
  end

  # maps SMF events to RRTS MidiEvents
  CmdType = { 0x8=>NoteOffEvent,
              0x9=>NoteOnEvent,
              0xa=>KeypressEvent,
              0xb=>ControllerEvent,
              0xc=>ProgramChangeEvent,
              0xd=>ChannelPressureEvent,
              0xe=>PitchbendEvent }

  # reads one complete track from the file
  def read_track track, track_end
    tick = 0
    last_cmd = nil
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
        # running status
        @file.ungetbyte c
        cmd = last_cmd or invalid
      end
      status = cmd >> 4
      ch = cmd & 0x0f # but not always
      case status
      when 0x8
        value = read_byte & 0x7f
        read_byte
        event = NoteOffEvent.new ch, value
      when 0x9, 0xa
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
        event = ProgramChange.new ch, (read_byte & 0x7f)
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
            skip len - 1
          when 0x2f  # end of track
            track.end_tick = tick
            skip(track_end - @file.pos)
            return
          when 0x51 # tempo
            invalid if len < 3
            if (smpte_timing) # SMPTE timing doesn't change
              skip(len)
            else
              event = TempoEvent.new
              NOFRIGGINGIDEA
=begin
                                     event->type = SND_SEQ_EVENT_TEMPO;
                                     event->port = port;
                                     event->tick = tick;
                                     event->data.tempo = read_byte() << 16;
                                     event->data.tempo |= read_byte() << 8;
                                     event->data.tempo |= read_byte();
                                     skip(len - 3);
=end
            end
          else # ignore all other meta events
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
    #  the curren position is immediately after the "MThd" id
    header_len = read_int(4)
    fail("#@file_name: invalid file format") if header_len < 6
    type = read_int 2
    if type != 0 && type != 1
      fail "#@file_name: type #{type} format is not supported"
    end
    num_tracks = read_int 2
    unless num_tracks.between?(1, 1000)
      fail "#@file_name: invalid number of tracks (#{num_tracks})"
    end
    time_division = read_int 2
    if time_division < 0
      fail "#@file_name: invalid time division (#{time_division})"
    end
    soundblock = Soundblock.new(time_division)
    # read tracks
    num_tracks.times do
      # search for MTrk chunk
      loop do
        id = read_id
        len = read_int 4 || fail("#@file_name: unexpected end of file when reading chunk")
        unless len.between?(0, 0x10000000 - 1)
          fail("#@file_name: invalid chunk length #{len}")
        end
        break if id == MTRK
        skip len
      end
      track = new Track
      read_track(track, @file.pos + len)
      soundblock << track
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
      case read_id
      when MTHD then read_smf
      when RIFF then read_riff
      else fail("#@file_name is not a Standard MIDI File")
      end
    end
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
        Player.new(sequencer, soundblock, @options[:ports]).play
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

