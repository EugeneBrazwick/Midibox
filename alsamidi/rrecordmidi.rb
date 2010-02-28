#!/usr/bin/ruby1.9.1 -w
=begin
 * rrecordmidi.rb - record standard MIDI files from sequencer ports
 *
 * Copyright (c) 2004-2005 Clemens Ladisch <clemens@ladisch.de>
 *
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

ARA: copied src at 17 feb 2010
* Copyright (c) 2010 Arnoud Rattink <arnoud@rattink.com>

IMPORTANT: never been tested on writing correct MIDI files!
20-feb-2010 11:39  tested with DOINK on keyboard.  Played back with aplaymidi. Seemed OK!

=end

# /* TODO: sequencer queue timer selection */

require_relative 'rrts'

include RRTS::Driver

BUFFER_SIZE = 4088

# ARA: added. Probably a define in the original Makefile.
SND_UTIL_VERSION_STR = '1.0'

# linked list of buffers, stores data as in the .mid file
class Buffer    # buffer
private
  def initialize
    @buf = ''
    @buf.encode 'ascii-8bit'
  end
public
  attr :next; # Buffer
  attr :buf; # string
end

class Smf_track # smf_track
private
  def initialize
    @first_buf = Buffer.new
    @cur_buf = @first_buf
    @size = @last_tick = 0
    @used = false
  end

public
  attr_accessor :size # size of entire data
  attr :cur_buf # Buffer *cur_buf;
  attr_accessor :last_tick, # end of track
                :last_command # used for running status

  def used? # anything record on this track
    @used
  end

  attr_writer :used
  attr :first_buf # list head
end

# timing/sysex + 16 channels
TRACKS_PER_PORT = 17

# metronome settings
#  TODO: create options for this
METRONOME_CHANNEL = 9
METRONOME_STRONG_NOTE = 34
METRONOME_WEAK_NOTE = 33
METRONOME_VELOCITY = 100
METRONOME_PROGRAM = 0

@ports = []
@smpte_timing = false
@beats = 120
@frames = 0
@ticks = 0
@channel_split = false
@tracks = []
@stop = false # ? static volatile sig_atomic_t stop = 0;  SET BY SIGNAL HANDLER
@use_metronome = false # metronome_port
@metronome_port =  nil
@metronome_weak_note = METRONOME_WEAK_NOTE
@metronome_strong_note = METRONOME_STRONG_NOTE
@metronome_velocity = METRONOME_VELOCITY
@metronome_program = METRONOME_PROGRAM
@metronome_channel = METRONOME_CHANNEL
@ts_num = 4 #  time signature: numerator
@ts_div = 4 # time signature: denominator
@ts_dd = 2 # time signature: denominator as a power of two

def init_seq
  #       open sequencer
  @seq = snd_seq_open
  #   puts "seq=#@seq"
  # find out our client's id
  @client = @seq.client_id
   # set our client's name
  @seq.client_name = 'rrecordmidi'
end

#  Metronome implementation
def metronome_note note, tick
  ev = ev_malloc
  ev.clear
  ev.set_note @metronome_channel, note, @metronome_velocity, 1
  ev.schedule_tick @queue, 0, tick
  ev.source_port = @ports.length
  ev.set_subs
  @seq.event_output ev
end

def metronome_echo tick  # unsigned int tick
  ev = ev_malloc # snd_seq_event_t ev;
  ev.clear
  ev.type = SND_SEQ_EVENT_USR0
  ev.schedule_tick @queue, 0, tick
  ev.source_port = @ports.length
  ev.set_dest @client, @ports.length
  @seq.event_output ev
end

def metronome_pattern tick
  t = tick
  duration = ticks * 4 / @ts_div
  for j in (0...@ts_num)
     metronome_note(j ? @metronome_weak_note : @metronome_strong_note, t)
     t += duration
  end
  metronome_echo t
  seq.drain_output
end

def metronome_set_program
  ev = ev_malloc
  ev.clear
  ev.set_pgmchange @metronome_channel, @metronome_program
  ev.source_port = @ports.length
  ev.set_subs
  @seq.event_output ev
end

def create_queue
  @queue = @seq.alloc_named_queue 'rrecordmidi'
  tempo = snd_seq_queue_tempo_malloc
  if !@smpte_timing
    tempo.tempo = 60_000_000 / @beats
    tempo.ppq = @ticks
  else
# ALSA doesn't know about the SMPTE time divisions, so
# we pretend to have a musical tempo with the equivalent
# number of ticks/s.
    case @frames
    when 24
      tempo.tempo = 500_000
      tempo.ppq = 12 * @ticks
    when 25
      tempo.tempo = 400_000
      tempo.ppq = 10 * @ticks
    when 29
      tempo.tempo = 100_000_000
      tempo.ppq = 2997 * @ticks
    when 30
      tempo.tempo = 500_000
      tempo.ppq = 15 * @ticks
      snd_seq_queue_tempo_set_tempo(tempo, 500000);
    else
      fail
    end
  end
  @seq.set_queue_tempo @queue, tempo
end

def create_ports
  pinfo =  snd_seq_port_info_malloc
#         common information for all our ports
  pinfo.capability = SND_SEQ_PORT_CAP_WRITE | SND_SEQ_PORT_CAP_SUBS_WRITE
  pinfo.type = SND_SEQ_PORT_TYPE_MIDI_GENERIC | SND_SEQ_PORT_TYPE_APPLICATION
  pinfo.midi_channels = 16
#         we want to know when the events got delivered to us
  pinfo.timestamping = true
  pinfo.timestamp_queue = @queue
#         our port number is the same as our port index
  pinfo.port_specified = true
  for i in (0...@ports.length)
    pinfo.port = i
    pinfo.name = "rrecordmidi port #{i}"
    @seq.create_port pinfo
  end
#         create an optional metronome port
  if @use_metronome
    pinfo.port = @ports.length
    pinfo.name = 'rrecordmidi metronome'
    pinfo.capability = SND_SEQ_PORT_CAP_READ | SND_SEQ_PORT_CAP_WRITE
    pinfo.type = SND_SEQ_PORT_TYPE_APPLICATION
    pinfo.midi_channels = 0
    pinfo.timestamping = false
    @seq.create_port pinfo
  end
end

def connect_ports
  @ports.each_with_index do |port, i|
#     puts "calling seq.connect_from(#{i}, #{port.inspect})"
    @seq.connect_from(i, port)
  end
#         subscribe the metronome port
  @use_metronome and @seq.connect_to(@ports.length, @metronome_port)
end

# records a byte to be written to the .mid file
def add_byte track, byte
#        make sure we have enough room in the current buffer
  if track.cur_buf.buf.length >= BUFFER_SIZE
    track.cur_buf.next = Buffer.new
    track.cur_buf = track.cur_buf.next
  end
  track.cur_buf.buf << byte
  track.size += 1
end

# record a variable-length quantity
def var_value track, v
  add_byte(track, 0x80 | ((v >> 28) & 0x03)) if v >= (1 << 28)
  add_byte(track, 0x80 | ((v >> 21) & 0x7f)) if v >= (1 << 21)
  add_byte(track, 0x80 | ((v >> 14) & 0x7f)) if v >= (1 << 14)
  add_byte(track, 0x80 | ((v >> 7) & 0x7f)) if v >= (1 << 7)
  add_byte(track, v & 0x7f)
end

# record the delta time from the last event
def delta_time track, ev
  diff = ev.time_tick - track.last_tick
  diff = 0 if diff < 0
#   STDERR.printf "ARA:%d:diff=%d, ev.time.tick=%d, last=%d\n", __LINE__, diff, ev.time_tick, track.last_tick
  var_value(track, diff)
  track.last_tick = ev.time_tick
end

# record a status byte (or not if we can use running status)
def command track, cmd
  add_byte(track, cmd) if cmd != track.last_command
  track.last_command = cmd < 0xf0 ? cmd : 0
end

# put port numbers into all tracks
def record_port_numbers
  @tracks.each_with_index do |track, i|
    var_value track, 0
    add_byte track, 0xff
    add_byte track, 0x21
    var_value track, 1
    if @channel_split
      add_byte track, i / TRACKS_PER_PORT
    else
      add_byte track, i
    end
  end
end

def record_event ev
#         ignore events without proper timestamps
  return if ev.queue != @queue || !ev.tick?
#         determine which track to record to
  i = ev.dest_port
  if i == @ports.length
    metronome_pattern ev.time_tick if ev.type == SND_SEQ_EVENT_USR0
    return
  end
  if @channel_split
    i *= TRACKS_PER_PORT
    i += 1 + (ev.channel & 0xf) if ev.channel_type?
  end
  return if i >= @tracks.length
  track = @tracks[i]
  case ev.type
  when SND_SEQ_EVENT_NOTEON
    delta_time track, ev
    command(track, MIDI_CMD_NOTE_ON | (ev.channel & 0xf))
    add_byte(track, ev.note & 0x7f)
    add_byte(track, ev.velocity & 0x7f)
  when SND_SEQ_EVENT_NOTEOFF
    delta_time track, ev
    command(track, MIDI_CMD_NOTE_OFF | (ev.channel & 0xf))
    add_byte(track, ev.note & 0x7f)
    add_byte(track, ev.velocity & 0x7f)
  when SND_SEQ_EVENT_KEYPRESS
    delta_time(track, ev)
    command(track, MIDI_CMD_NOTE_PRESSURE | (ev.channel & 0xf))
    add_byte(track, ev.note & 0x7f)
    add_byte(track, ev.velocity & 0x7f)
  when SND_SEQ_EVENT_CONTROLLER
    delta_time(track, ev)
    command(track, MIDI_CMD_CONTROL | (ev.channel & 0xf))
    add_byte(track, ev.param & 0x7f)
    add_byte(track, ev.value & 0x7f)
  when SND_SEQ_EVENT_PGMCHANGE
    delta_time(track, ev)
    command(track, MIDI_CMD_PGM_CHANGE | (ev.channel & 0xf))
    add_byte(track, ev.value & 0x7f)
  when SND_SEQ_EVENT_CHANPRESS
    delta_time(track, ev)
    command(track, MIDI_CMD_CHANNEL_PRESSURE | (ev.channel & 0xf))
    add_byte(track, ev.value & 0x7f)
  when SND_SEQ_EVENT_PITCHBEND
    delta_time(track, ev)
    command(track, MIDI_CMD_BENDER | (ev.channel & 0xf))
    add_byte(track, (ev.value + 8192) & 0x7f)
    add_byte(track, ((ev.value + 8192) >> 7) & 0x7f)
  when SND_SEQ_EVENT_CONTROL14
#    create two commands for MSB and LSB
    delta_time(track, ev);
    command(track, MIDI_CMD_CONTROL | (ev.channel & 0xf));
    add_byte(track, ev.param & 0x7f);
    add_byte(track, (ev.value >> 7) & 0x7f);
    if (ev.param & 0x7f) < 0x20
      delta_time(track, ev)
#   running status
      add_byte(track, (ev.param & 0x7f) + 0x20)
      add_byte(track, ev.value & 0x7f);
    end
  when SND_SEQ_EVENT_NONREGPARAM
    delta_time(track, ev)
    command(track, MIDI_CMD_CONTROL | (ev.channel & 0xf))
    add_byte(track, MIDI_CTL_NONREG_PARM_NUM_LSB)
    add_byte(track, ev.param & 0x7f)
    delta_time(track, ev)
    add_byte(track, MIDI_CTL_NONREG_PARM_NUM_MSB)
    add_byte(track, (ev.param >> 7) & 0x7f)
    delta_time(track, ev);
    add_byte(track, MIDI_CTL_MSB_DATA_ENTRY);
    add_byte(track, (ev.value >> 7) & 0x7f);
    delta_time(track, ev);
    add_byte(track, MIDI_CTL_LSB_DATA_ENTRY);
    add_byte(track, ev.value & 0x7f);
  when SND_SEQ_EVENT_REGPARAM
    delta_time(track, ev);
    command(track, MIDI_CMD_CONTROL | (ev.channel & 0xf));
    add_byte(track, MIDI_CTL_REGIST_PARM_NUM_LSB);
    add_byte(track, ev.param & 0x7f);
    delta_time(track, ev);
    add_byte(track, MIDI_CTL_REGIST_PARM_NUM_MSB);
    add_byte(track, (ev.param >> 7) & 0x7f);
    delta_time(track, ev);
    add_byte(track, MIDI_CTL_MSB_DATA_ENTRY);
    add_byte(track, (ev.value >> 7) & 0x7f);
    delta_time(track, ev);
    add_byte(track, MIDI_CTL_LSB_DATA_ENTRY);
    add_byte(track, ev.value & 0x7f);
  when SND_SEQ_EVENT_SYSEX
    sysex = ev.sysex
    unless sysex.empty?
      delta_time(track, ev);
      if sysex.byte(0) == 0xf0 # *(unsigned char*)ev->data.ext.ptr == 0xf0)
        command(track, 0xf0)
        skipfirst = true
      else
        command(track, 0xf7)
        skipfirst = false
      end
      var_value(track, sysex.length - i)
      for b in sysex.bytes
        if skipfirst
          skipfirst = false
        else
          add_byte(track, b)
        end
      end
    end
  else
    return
  end
  track.used = true
end

def finish_tracks
  queue_status = @seq.queue_status @queue
  tick = queue_status.tick_time
#         make length of first track the recording length
  tick_track = tick - @tracks[0].last_tick
  for track in @tracks
    var_value(@tracks[0], tick_track)
    tick_track = 0
    add_byte(track, 0xff)
    add_byte(track, 0x2f);
    var_value(track, 0);
  end
#         finish other tracks
end

def write_file
  used_tracks = @tracks.count { |track| track.used? }
  #         header id and length
  @file.write "MThd\0\0\0\6"
  #  type 0 or 1
  @file.putc 0
  @file.putc used_tracks > 1 ? 1 : 0
  #  number of tracks
  @file.putc((used_tracks >> 8) & 0xff)
  @file.putc(used_tracks & 0xff)
#         time division
  time_division = @ticks;
  time_division |= ((0x100 - @frames) << 8) if @smpte_timing
  @file.putc(time_division >> 8)
  @file.putc(time_division & 0xff)

  for track in @tracks
    next unless track.used?
#                track id
    @file.write("MTrk")
#  data length
    @file.putc((track.size >> 24) & 0xff)
    @file.putc((track.size >> 16) & 0xff)
    @file.putc((track.size >> 8) & 0xff)
    @file.putc(track.size & 0xff)
#  track contents
    buf = track.first_buf
    while buf
      @file.write buf.buf
      buf = buf.next
    end
  end
end

require 'optparse'
opts = OptionParser.new
opts.banner = "Usage: #{$PROGRAM_NAME} [options] outputfile"
opts.on('-h', '--help', 'this help') { puts opts.to_s; exit 1 }
opts.on('-V', '--version', 'show version') { STDERR.puts("rrecordmidi version #{SND_UTIL_VERSION_STR}\n"); exit }
opts.on('-l', '--list', 'list input ports') do
  cinfo = snd_seq_client_info_malloc
  pinfo = snd_seq_port_info_malloc
  puts(" Port    Client name                      Port name")
  cinfo.client = -1
  while @seq.next_client(cinfo)
    client = cinfo.client
    next if client == SND_SEQ_CLIENT_SYSTEM #  don't show system timer and announce ports
    pinfo.client = client
    pinfo.port = -1
    while @seq.next_port(pinfo)
      #    port must understand MIDI messages
      next if !(pinfo.type & SND_SEQ_PORT_TYPE_MIDI_GENERIC)
      #  we need both READ and SUBS_READ
      next if (pinfo.capability & (SND_SEQ_PORT_CAP_READ | SND_SEQ_PORT_CAP_SUBS_READ)) !=
              (SND_SEQ_PORT_CAP_READ | SND_SEQ_PORT_CAP_SUBS_READ)
      printf("%3d:%-3d  %-32.32s %s\n", pinfo.client, pinfo.port, cinfo.name, pinfo.name)
    end
  end
  exit 0
end

opts.on('-p', '--port=VAL', 'source port(s)') do |port|
#  parses one or more comma separated port addresses from the string
  @ports = port.split(',').map { |port_name| @seq.parse_address port_name }
  #  Assume that ports are separated by commas.  We don't use
  #  spaces because those are valid in client names.
end

opts.on('-b', '--bpm=VAL', Integer, 'tempo in beats per minute') do |bpm|
  raise OptionParser::InvalidArgument.new("Invalid tempo #{bpm}") unless (4..6000) === bpm
  @beats = bpm
  @smpte_timing = false
end

opts.on('-f', '--fps=VAL', Integer, [24, 25, 39, 30], 'use frames per second') do |fps|
  @frames = fps
  @smpte_timing = true
end

opts.on('-t', '--ticks=VAL', Integer, 'use ticks per beat or frame') do |ticks|
  raise OptionParser::InvalidArgument.new('Invalid number of ticks') unless (1..0x7fff) === ticks
  @ticks = ticks
end

opts.on('-m', '--metronome=VAL', 'play a metronome signal') { |metronome| @metronome_port = @seq.parse_address(metronome) }
opts.on('-i', '--timesig=VAL', /\d+:\d+/, 'time signature') do |timesig|
  # parses time signature specification pe 34:60  or whatever
  # ASSIGNs to ts_num, ts_div, ts_dd
  @ts_num, @ts_div = timesig.scan(/(\d+):(\d+)/)
  raise OptionParser::InvalidArgument.new("Invalid time signature (#{timesig})") unless (1 .. 64) === @ts_num && (1 .. 64) === @ts_div
  x = @ts_div
  @ts_dd = 0
  while x > 1
    x /= 2
    @ts_dd += 1
  end
end

opts.on('-s', '--[no-]channel-split') { |val| @channel_split = val }

# trace

init_seq

filename = opts.parse(ARGV)
fail("Please specify a file to record to.\n") if filename.empty?
help if filename.length > 1
filename = filename[0]
fail("Please specify a source port with --port.") if @ports.empty?

@ticks = @smpte_timing ? 40 : 384 if @ticks == 0
@ticks = 0xff if @smpte_timing && @ticks > 0xff

# MIDI RP-019 says we need at least one track per port
# Allocate one track for each possible channel.
# Empty tracks won't be written to the file.
@tracks = Array.new(@ports.length * (@channel_split ? TRACKS_PER_PORT : 1)) { Smf_track.new }
create_queue
create_ports
connect_ports
record_port_numbers if @ports.length > 1

#         /* record tempo */
unless @smpte_timing
  usecs_per_quarter = 60_000_000 / @beats;
  puts "usecs_per_quarter = #{usecs_per_quarter}"
  var_value(@tracks[0], 0); # /* delta time */
  add_byte(@tracks[0], 0xff);
  add_byte(@tracks[0], 0x51);
  var_value(@tracks[0], 3);
  add_byte(@tracks[0], usecs_per_quarter >> 16);
  add_byte(@tracks[0], (usecs_per_quarter >> 8) & 0xff);
  add_byte(@tracks[0], (usecs_per_quarter) & 0xff);
#                 time signature
  var_value(@tracks[0], 0); # delta time
  add_byte(@tracks[0], 0xff);
  add_byte(@tracks[0], 0x58);
  var_value(@tracks[0], 4);
  add_byte(@tracks[0], @ts_num);
  add_byte(@tracks[0], @ts_dd);
  add_byte(@tracks[0], 24); # MIDI clocks per metronome click
  add_byte(@tracks[0], 8); # notated 32nd-notes per MIDI quarter note
end

# always write at least one track
@tracks[0].used = true
@file = open(filename, "wb:binary");
@seq.start_queue @queue
@seq.drain_output
@seq.nonblock

if @use_metronome
  metronome_set_program
  metronome_pattern 0
end

Signal.trap('INT') { @stop = true }
Signal.trap('TERM') { @stop = true }

# FIXME. this is a busy loop. Why not just use blocking ???
npfds = @seq.poll_descriptors_count(POLLIN);
until @stop do
#   trace do
    descriptors = @seq.poll_descriptors(npfds, POLLIN);
    revents = @seq.poll_descriptors_revents(descriptors)
#   end
  more = true
  until @stop || !more
    (event, more = @seq.event_input) or break
    record_event event
  end
end
# trace
finish_tracks
write_file
@file.close
@seq.close
