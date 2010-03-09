#!/usr/bin/ruby -w
# 1.9.1 required (1.8 does NOT work!)

=begin
 * rplaymidi.rb - play Standard MIDI Files to sequencer port(s)
 * This is a one on one port of aplaymidi.c by Clemens Ladish
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

#  TODO: sequencer queue timer selection

=begin
KNOWN BUGS

Somehow I get a duration of 500_000 for all notes.... ??
But then again, the program writes tempo in ev and it uses only a single ev that
is overwritten (partly!).
So this may very well be 'normal' behaviour.

Violates MIDI standard by not sending NOTEOFF for all NOTEONs.  Fails when INTR
is pressed (or whatever other killing signal).
This too is an issue with aplaymidi to begin with.

NOTEON-OFF : OK.
anything else cause Roland to behave badly with hanging notes etc..
panic.rb helps only temporarily!!
Removing sysex did not help. Something is off with the programchanges, at least.

And Roland E-80 is not idiot proof so it seems ):

=end

require_relative 'rrts'

=begin
 * 31.25 kbaud, one start bit, eight data bits, two stop bits.
 * (The MIDI spec says one stop bit, but every transmitter uses two, just to be
 * sure, so we better not exceed that to avoid overflowing the output buffer.)
=end

include RRTS::Driver

=begin
 * A MIDI event after being parsed/loaded from the file.
=end
class Event # :no-doc:

  attr_accessor :type, :port, :tick, :d, :tempo, :length, :sysex

  # struct event *next;		/* linked list */

 #	unsigned char type;		/* SND_SEQ_EVENT_xxx */
# 	unsigned char port;		/* port index */
# 	unsigned int tick;
# 	union {
# 		unsigned char d[3];	/* channel and data bytes */
# 		int tempo;
# 		unsigned int length;	/* length of sysex data */
# 	} data;
# 	unsigned char sysex[0];
end # event

class Track # :no-doc:
# 	struct event *first_event;	/* list of all events in this track */
# 	int end_tick;			/* length of this track */
#
# 	struct event *current_event;	/* used while loading and playing */
private
  def initialize
    @events = []
    rewind
  end

public
  attr_accessor :end_tick
  attr :events

  def current_event
    @events[@ptr]
  end

  def next
    @ptr += 1
  end

  def rewind
    @ptr = 0
  end
end # class Track

@end_delay = 2

# /* prints an error message to stderr */
def errormsg msg, *args
  STDERR.printf(msg, *args)
  STDERR.puts
end

# /* prints an error message to stderr, and dies */
def fatal msg, *args
  STDERR.printf(stderr, msg, *args)
  STDERR.puts
  exit 1
end

# /* error handling for ALSA functions */    rrts uses exceptions...
# static void check_snd(const char *operation, int err)
# {
# 	if (err < 0)
# 		fatal("Cannot %s - %s", operation, Driver::strerror(err));
# }

def init_seq
#   /* open sequencer */
  @seq = Driver::seq_open
#   	/* set our name (otherwise it's "Client-xxx") */
  @seq.client_name = "aplaymidi"
  #@seq.dump_notes = true  # requires DEBUG to be set. This disables output!!!
# 	/* find out who we actually are */
  @client = @seq.client_id
end

@port_count = 0

# /* parses one or more port addresses from the string */
def parse_ports arg
# 	char *buf, *s, *port_name;
# 	int err;

# 	/* make a copy of the string because we're going to modify it */
  portnames = arg.split(',')
  @ports = []
  for name in portnames
    @port_count += 1
    @ports << @seq.parse_address(name)  # returns a tuple....
  end
end

def create_source_port
  pinfo = port_info_malloc

# 	/* the first created port is 0 anyway, but let's make sure ... */
  pinfo.port = 0
  pinfo.port_specified = true
  pinfo.name = "aplaymidi"

  pinfo.capability = 0 # /* sic */
  pinfo.type = SND_SEQ_PORT_TYPE_MIDI_GENERIC | SND_SEQ_PORT_TYPE_APPLICATION
  @seq.create_port(pinfo)
end

def create_queue
  @queue = @seq.alloc_named_queue "aplaymidi"
#   	/* the queue is now locked, which is just fine */
end

def connect_ports
# 	int i, err;

=begin
	 * We send MIDI events with explicit destination addresses, so we don't
	 * need any connections to the playback ports.  But we connect to those
	 * anyway to force any underlying RawMIDI ports to remain open while
	 * we're playing - otherwise, ALSA would reset the port after every
	 * event.
=end
  for i in (0...@port_count)
    @seq.connect_to(0, @ports[i][0], @ports[i][1])
  end
end

def read_byte
  @file_offset += 1
  @file.readbyte  # throws EOFError
end

#  reads a little-endian 32-bit integer
def read_32_le
# 	int value;
  value = read_byte
  value |= read_byte << 8
  value |= read_byte() << 16;
  (value |= read_byte() << 24)
#   .tap{|v| puts "read_32_le -> #{v}" }
end

# /* reads a 4-character identifier */
alias :read_id :read_32_le

def make_id(c1, c2, c3, c4)
  ((c1.ord) | ((c2.ord) << 8) | ((c3.ord) << 16) | ((c4.ord) << 24))
end

# /* reads a fixed-size big-endian number */
def read_int bytes
#   int c, value = 0;
  value = 0

  bytes.times {
    c = read_byte
    value = (value << 8) | c;
  }
#   puts "read_int -> #{value}"
  value
end

# /* reads a variable-length number */
def read_var
# 	int value, c;
  c = read_byte
  value = c & 0x7f;
  if (c & 0x80) != 0
    c = read_byte
    value = (value << 7) | (c & 0x7f);
    if (c & 0x80) != 0
      c = read_byte
      value = (value << 7) | (c & 0x7f);
      if (c & 0x80)  != 0
        c = read_byte
        value = (value << 7) | c;
        return false if (c & 0x80) != 0
      end
    end
  end
#   puts "read_var -> #{value}"
  value
end

# /* allocates a new event */
def new_event track, sysex_length
#   	struct event *event;
  event = Event.new

# 	/* append at the end of the track's linked list */
  track.events << event
  event
end

def skip bytes
  bytes.times { read_byte }
end

def read_error
  errormsg("%s: invalid MIDI data (offset %#x)", @file_name, @file_offset);
end

CmdType = { 0x8=>SND_SEQ_EVENT_NOTEOFF,
            0x9=>SND_SEQ_EVENT_NOTEON,
            0xa => SND_SEQ_EVENT_KEYPRESS,
            0xb => SND_SEQ_EVENT_CONTROLLER,
            0xc => SND_SEQ_EVENT_PGMCHANGE,
            0xd => SND_SEQ_EVENT_CHANPRESS,
            0xe => SND_SEQ_EVENT_PITCHBEND
         }

# /* reads one complete track from the file */
def read_track track, track_end
#
  tick = 0;
  last_cmd = 0;
  port = 0;

# 	/* the current file position is after the track ID and length */
  while @file_offset < track_end
#     unsigned char cmd;
# 		struct event *event;
# 		int delta_ticks, len, c;

    delta_ticks = read_var or break
#     puts "delta_ticks=#{delta_ticks}"
    tick += delta_ticks;

    c = read_byte
    if (c & 0x80) != 0
#    		/* have command */
      cmd = c
      last_cmd = cmd if cmd < 0xf0
    else#          			/* running status */
      @file.ungetbyte(c);
      @file_offset -= 1;
      cmd = last_cmd;
      read_error if cmd == 0
    end
    case cmd >> 4
# 			/* maps SMF events to ALSA sequencer events */
    when 0x8, 0x9, 0xb, 0xe #* channel msg with 2 parameter bytes */
      event = new_event(track, 0)
      event.type = CmdType[cmd >> 4]
      event.port = port
      event.tick = tick
      d1 = read_byte & 0x7f
      d2 = read_byte & 0x7f
      event.d = [cmd & 0x0f, d1, d2]
#       puts "#{File.basename(__FILE__)}:#{__LINE__}:2 byte channel message #{event.type}, d1=#{d1},d2=#{d2}"
    when 0xc, 0xd  #/* channel msg with 1 parameter byte */
#       puts "1 byte channel message"
      event = new_event(track, 0);
      event.type = CmdType[cmd >> 4];
      event.port = port;
      event.tick = tick;
      d1 = read_byte() & 0x7f;
      event.d = [cmd & 0x0f, d1]
    when 0xf
      case cmd
      when 0xf0, 0xf7 #/* sysex */
                      #/* continued sysex, or escaped commands */
        len = read_var or read_error
        len += 1 if (cmd == 0xf0)
        event = new_event(track, len)
        event.type = SND_SEQ_EVENT_SYSEX;
        event.port = port;
        event.tick = tick;
#         event.length = len;
        event.sysex = ''
        event.sysex.force_encoding('ascii-8bit')
        if (cmd == 0xf0)
          event.sysex += 0xf0.chr
          c = 1;
        else
          c = 0
        end
        while c < len
          event.sysex += read_byte.chr
          c += 1
        end
      when 0xff #/* meta event */
        c = read_byte()
        len = read_var or read_error
        case (c)
        when 0x21 # * port number */
          read_error if (len < 1)
          port = read_byte() % @port_count;
          skip(len - 1);
        when 0x2f # /* end of track */
          track.end_tick = tick;
          skip(track_end - @file_offset)
          return true
        when 0x51 # /* tempo */
          read_error if (len < 3)
          if (@smpte_timing)
# 						/* SMPTE timing doesn't change */
            skip(len);
          else
            event = new_event(track, 0);
            event.type = SND_SEQ_EVENT_TEMPO;
            event.port = port;
            event.tick = tick;
            event.tempo = read_byte() << 16;
            event.tempo |= read_byte() << 8;
            event.tempo |= read_byte();
            skip(len - 3);
          end
        else # /* ignore all other meta events */
          skip(len);
        end
      else  #  /* invalid Fx command */
         read_error
      end
    else
      #  /* cannot happen */
      read_error
    end
  end
  errormsg("%s: invalid MIDI data (offset %#x)", @file_name, @file_offset);
  false
end

def invalid_format
  errormsg("%s: invalid file format", @file_name);
end

# /* reads an entire MIDI file */
def read_smf
# 	/* the curren position is immediately after the "MThd" id */
  header_len = read_int(4);
  invalid_format if (header_len < 6)

  type = read_int(2);
  if (type != 0 && type != 1)
    errormsg("%s: type %d format is not supported", @file_name, type);
    return false;
  end

  @num_tracks = read_int(2);
  if (@num_tracks < 1 || @num_tracks > 1000)
    errormsg("%s: invalid number of tracks (%d)", @file_name, @num_tracks);
    @num_tracks = 0;
    return false
  end
  @tracks = []
  time_division = read_int(2);
#   puts "time_division=#{time_division}"
# 	/* interpret and set tempo */
  queue_tempo = queue_tempo_malloc
  @smpte_timing = (time_division & 0x8000) != 0
  if (!@smpte_timing)
# 		/* time_division is ticks per quarter */
    queue_tempo.tempo = 500_000 #); /* default: 120 bpm */
    queue_tempo.ppq = time_division
  else
# 		/* upper byte is negative frames per second */
    i = 0x80 - ((time_division >> 8) & 0x7f);
# 		/* lower byte is ticks per frame */
    time_division &= 0xff;
# 		/* now pretend that we have quarter-note based timing */
    case (i)
    when 24
      queue_tempo.tempo = 500_000
      queue_tempo.ppq = 12 * time_division
    when 25
      queue_tempo.tempo = 400_000
      queue_tempo.ppq = 10 * time_division
    when 29 # /* 30 drop-frame */
      queue_tempo.tempo = 100_000_000
      queue_tempo.ppq = 2997 * time_division
    when 30
      queue_tempo.tempo = 500_000
      queue_tempo.ppq = 15 * time_division
    else
      errormsg("%s: invalid number of SMPTE frames per second (%d)",
				 @file_name, i);
      return false
    end
  end
  @seq.set_queue_tempo(@queue, queue_tempo)
#    	/* read tracks */
  for i in (0...@num_tracks)
# 		int len;

# 		/* search for MTrk chunk */
    len = 0
    loop do
      id = read_id();
      len = read_int(4);
      if (len < 0 || len >= 0x10000000)
        errormsg("%s: invalid chunk length %d", @file_name, len);
        return false
      end
      break if (id == make_id('M', 'T', 'r', 'k'))
      skip(len);
    end
    @tracks[i] = Track.new
    return false unless read_track(@tracks[i], @file_offset + len)
  end
  true
end

def read_riff
# 	/* skip file length */
  4.times { read_byte(); }
#   	/* check file type ("RMID" = RIFF MIDI) */
  invalid_format if (read_id() != make_id('R', 'M', 'I', 'D'))
#  	/* search for "data" chunk */
  loop do
    id = read_id();
    len = read_32_le();
    break if (id == make_id('d', 'a', 't', 'a'))
    skip((len + 1) & ~1);
  end
#   	/* the "data" chunk must contain data in SMF format */
  invalid_format if (read_id() != make_id('M', 'T', 'h', 'd'))
  read_smf
end

def cleanup_file_data
# 	int i;
# 	struct event *event;

  @num_tracks = 0;
  @tracks = nil;
end

def handle_big_sysex ev
#
# 	unsigned int length;
# 	ssize_t event_size;
# 	int err;
  sysex = ev.sysex
  event_size = ev.length # required bufferspace
  if event_size >= @seq.output_buffer_size
    @seq.drain_output
    @seq.output_buffer_size = event_size + 1
  end
  l = sysex.length
  offset = 0
  while l > MIDI_BYTES_PER_SEC
    ev.sysex = sysex[0, MIDI_BYTES_PER_SEC]
    @seq.event_output ev
    @seq.drain_output
    @seq.sync_output_queue
    sleep(1)  # AARGH
    l -= MIDI_BYTES_PER_SEC
    offset += MIDI_BYTES_PER_SEC
    # l > 0
  end
  ev.sysex = sysex[offset, l]
end

def play_midi
#calculate length of the entire file
  max_tick = -1;
  for i in (0...@num_tracks)
    if (@tracks[i].end_tick > max_tick)
      max_tick = @tracks[i].end_tick;
    end
  end

#   	/* initialize current position in each track */
  for i in (0...@num_tracks) do @tracks[i].rewind end
# 	/* common settings for all our events */
  ev = ev_malloc # non alsa
  ev.clear
#   puts "ev cleared-> #{ev.inspect}"
  ev.queue = @queue;
  ev.source_port = 0;
  ev.flags = SND_SEQ_TIME_STAMP_TICK;
#   puts "ev used for all-> #{ev.inspect}"

  @seq.start_queue(@queue);
# 	/* The queue won't be started until the START_QUEUE event is
# 	 * actually drained to the kernel, which is exactly what we want. */

  loop do
    event = nil
    event_track = nil
    min_tick = max_tick + 1;

# 		/* search next event */
    for i in (0...@num_tracks)
      track = @tracks[i];
      e2 = track.current_event
      if (e2 && e2.tick < min_tick)
        min_tick = e2.tick;
        event = e2;
	event_track = track;
      end
    end
    break unless event # ; /* end of song reached */
#     puts "read event from track, event=#{event.inspect}"
    event_track.next

 # 		/* output the event */
    ev.type = event.type;
    ev.time_tick = event.tick;
    ev.dest = @ports[event.port];
#     puts "ev before typeswitch-> #{ev.inspect}"
    case (ev.type)
    when SND_SEQ_EVENT_NOTEON, SND_SEQ_EVENT_NOTEOFF
      ev.set_fixed
      ev.channel = event.d[0];
      ev.note = event.d[1];
      ev.velocity = event.d[2];
#       puts "ev NOTEON/OFF:-> #{ev.inspect}"
    when SND_SEQ_EVENT_KEYPRESS
      next if @only_notes
      ev.set_fixed
      ev.channel = event.d[0];
      ev.note = event.d[1];
      ev.velocity = event.d[2];
    when SND_SEQ_EVENT_CONTROLLER
      next if @only_notes
      ev.set_fixed
      ev.channel = event.d[0];
#       STDERR.puts("#{File.basename(__FILE__)}:#{__LINE__}:CONTROLLER, param = #{event.d[1]}")
      ev.param = event.d[1]
      ev.value = event.d[2]
#       STDERR.puts("ev.param=#{ev.param}, ev.value=#{ev.value}")
    when SND_SEQ_EVENT_PGMCHANGE, SND_SEQ_EVENT_CHANPRESS
      next if @only_notes
      ev.set_fixed
      ev.channel = event.d[0];
      ev.value = event.d[1];
    when SND_SEQ_EVENT_PITCHBEND
      next if @only_notes
      ev.set_fixed
      ev.channel = event.d[0];
      ev.value = ((event.d[1]) | ((event.d[2]) << 7)) - 0x2000;
    when SND_SEQ_EVENT_SYSEX
      next if @no_sysex
      ev.set_variable event.sysex
      handle_big_sysex ev
    when SND_SEQ_EVENT_TEMPO
      ev.set_fixed
      ev.dest_client = SND_SEQ_CLIENT_SYSTEM;
      ev.dest_port = SND_SEQ_PORT_SYSTEM_TIMER;
      ev.queue_queue = @queue;
      ev.queue_value = event.tempo;
    else
      fatal("Invalid event type %d!", ev.type);
    end
  # 		/* this blocks when the output pool has been filled */
    @seq.event_output ev
  end
#  	/* schedule queue stop at end of song */
  ev.set_fixed
  ev.type = SND_SEQ_EVENT_STOP;
  ev.time_tick = max_tick;
  ev.dest_client = SND_SEQ_CLIENT_SYSTEM;
  ev.dest_port = SND_SEQ_PORT_SYSTEM_TIMER;
  ev.queue_queue = @queue;
  @seq.event_output ev
# 	/* make sure that the sequencer sees all our events */
  @seq.drain_output
=begin
      /*
       * There are three possibilities how to wait until all events have
       * been played:
       * 1) send an event back to us (like pmidi does), and wait for it;
       * 2) wait for the EVENT_STOP notification for our queue which is sent
       *    by the system timer port (this would require a subscription);
       * 3) wait until the output pool is empty.
       * The last is the simplest.
       */
=end
  @seq.sync_output_queue
#
# 	/* give the last notes time to die away */
  sleep(@end_delay) if (@end_delay > 0)
end

def play_file
# 	int ok;
#
  if (@file_name == "-")
    @file = STDIN
  else
    @file = File::open(@file_name, "rb");
  end
  @file_offset = 0
  ok = false
  case (read_id())
  when make_id('M', 'T', 'h', 'd')
    ok = read_smf
  when make_id('R', 'I', 'F', 'F')
    ok = read_riff
  else
    errormsg("%s is not a Standard MIDI File", @file_name);
  end
  @file.close if @file != STDIN
  require 'yaml'
  File.open("./rplaymidi.yaml", "w") { |file| YAML.dump(@tracks, file) }
  ok and play_midi
  cleanup_file_data
end

def list_ports
  cinfo = client_info_malloc
  pinfo = port_info_malloc
  puts " Port    Client name                      Port name"
  cinfo.client = -1
  while @seq.query_next_client(cinfo)
    client = cinfo.client
    pinfo.client = client
    pinfo.port = -1
    while @seq.query_next_port(pinfo)
# 			/* port must understand MIDI messages */
      next if (!(pinfo.type & SND_SEQ_PORT_TYPE_MIDI_GENERIC))
# 			/* we need both WRITE and SUBS_WRITE */
      next if (pinfo.capability & (SND_SEQ_PORT_CAP_WRITE | SND_SEQ_PORT_CAP_SUBS_WRITE)) !=
              (SND_SEQ_PORT_CAP_WRITE | SND_SEQ_PORT_CAP_SUBS_WRITE)
      printf("%3d:%-3d  %-32.32s %s\n",
	pinfo.client, pinfo.port, cinfo.name, pinfo.name);
    end
  end
end

def usage argv0
  printf(
		"Usage: %s -p client:port[,...] [-d delay] midifile ...\n" +
		"-h, --help                  this help\n" +
		"-V, --version               print current version\n" +
		"-l, --list                  list all possible output ports\n" +
		"-p, --port=client:port,...  set port(s) to play to\n" +
		"-d, --delay=seconds         delay after song ends\n",
		argv0);
end

SND_UTIL_VERSION_STR = '1.0'

def version
  puts("aplaymidi version " + SND_UTIL_VERSION_STR);
end

require 'optparse'
@no_sysex = @only_notes = false
opts = OptionParser.new
opts.banner = "Usage: #$PROGRAM_NAME [options] inputfile ..."
opts.on('-h', '--help', 'this help') { usage($0); exit 1; }
opts.on('-V', '--version', 'show version') { version; exit }
opts.on('-l', '--list', 'list output ports') { list_ports; exit }
opts.on('-p', '--port=VAL', 'comma separated list of ports') { |arg| parse_ports(arg) }
opts.on('-d', '--delay=VAL', 'exit delay', Integer) { |d| @end_delay = d }
opts.on('-S', '--no-sysex', 'do not play sysex') { @no_sysex = true }
opts.on('-N', '--only-note', 'only_notes') { @no_sysex = @only_notes = true }
init_seq();
file_names = opts.parse ARGV

if @port_count < 1
# 			/* use env var for compatibility with pmidi */
  ports_str = ENV["ALSA_OUTPUT_PORTS"]
  parse_ports(ports_str) if ports_str && !ports_str.empty?
  if @port_count < 1
    errormsg "Please specify at least one port with --port."
    exit 1
  end
end
if file_names.empty?
  errormsg "Please specify a file to play."
  exit 1
end
create_source_port
create_queue
connect_ports

for file_name in file_names
  @file_name = file_name
  play_file
end
@seq.close
