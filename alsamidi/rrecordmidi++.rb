#!/usr/bin/ruby1.9.1 -w
# encoding: utf-8

=begin
 * rrecordmidi++.rb - record standard MIDI files from sequencer ports
 *
 * Ported from alsa-utils/seq/aplaymidi/arecordmidi.c
 *
 * Original:
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

This is the Object Oriented version of rrecordmidi.rb.
=end

require_relative './alsa_midi.so'

include RRTS::Driver

BUFFER_SIZE = 4088

# ARA: added. Probably a define in the original Makefile.
SND_UTIL_VERSION_STR = '1.0'

# linked list of buffers, stores data as in the .mid file
class Buffer    # buffer
private
  def initialize
    @buf = ''
    @buf.force_encoding 'ascii-8bit'
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

@source_ports = []  # Port array as passed to --port/-p
@myports = [] # one on one mapping to @source_ports
@smpte_timing = false
@beats = 120  # quarters per minute
@frames = 0
@ticks = nil   # default 384 ticks per quarter.
@channel_split = false
@tracks = []
@stop = false # ? static volatile sig_atomic_t stop = 0;  SET BY SIGNAL HANDLER
@metronome = nil
@ts_num = 4 #  time signature: numerator, default is 4 quarters per bar
@ts_div = 4 # time signature: denominator, default is quarters
@ts_dd = 2 # time signature: denominator as a power of two, wholes is 0, halves =1 ,quarters=2,eights=3,sixteenths=4

class Metronome
#  Metronome implementation. Context: pattern
  private
  # metronome default settings
  CHANNEL = 10
  STRONG_NOTE = 34
  WEAK_NOTE = 33
  VELOCITY = 100
  PROGRAM = 0

  def initialize queue, source_port, params = nil
    @sequencer, @queue, @source_port = queue.sequencer, queue, source_port
    @weak_note = WEAK_NOTE
    @strong_note = STRONG_NOTE
    @velocity = VELOCITY
    @program = PROGRAM
    @channel = CHANNEL
    @ts_num = @ts_div = 4
    port = nil
    if params
      for k, v in params
        case k
        when :weak_note then @weak_note = v
        when :strong_note then @strong_note = v
        when :velocity then @velocity = v
        when :program then @program = v
        when :channel then @channel = v
        when :port then port = v
        when :ts_num then @ts_num = v
        when :ts_div then @ts_div = v
        else raise RRTSError.new("illegal option '#{k}' for Metronome")
        end
      end
    end
    @myport = MidiPort.new(@sequencer, 'rrecordmidi metronome',
                           port: port, read: true, write: true, application: true,
                           midi_channels: 0, timestamping: false)
    #  subscribe the metronome port
    @myport.⇒ @source_port
  end

  def note aNote, tick
    ev = NoteOnEvent.new(@channel, aNote, @velocity,
                         duration: 1,
                         source: @myport, dest: @sequencer.subscribers_unknown_port,
                         sender_queue: @queue, time_mode_absolute: true, # the default actually
                         tick: tick)
    @sequencer << ev
  end

  def echo tick  # unsigned int tick
    @sequencer << UserEvent.new(:usr0, source: @myport, dest: @myport,
                                sender_queue: @queue, tick: tick)
  end

  public

  def pattern tick
    t = tick
    duration = ticks * 4 / @ts_div
    for j in (0...@ts_num)
       note(j ? @weak_note : @strong_note, t)
       t += duration
    end
    echo t
    @sequencer.drain_output
  end

  def set_program
    @sequencer << ProgramChangeEvent.new(@channel, @program,
                                         source: @myport, dest: @sequencer.subscribers_unknown)
  end

  attr :myport

end # Metronome

def create_queue
  require_relative 'midiqueue'
  @queue = MidiQueue.new @sequencer, 'rrecordmidi',
                         tempo: Tempo.new(@smpte_timing ? @frames : @beats,
                                          smpte_timing: @smpte_timing,
                                          ticks: @ticks)
end

def create_ports
  params = { write: true, subs_write: true, midi_generic: true, application: true,
             midi_channels: 16, timestamping: true, timestamp_queue: @queue
            }
  #        our port number is the same as our port index
  for i in (0...@source_ports.length)
    params[:port] = i
    @myports << MidiPort.new(@sequencer, "rrecordmidi port #{i}", params)
  end
end

def connect_ports
  sp, mp = @source_ports.each, @myports.each
  loop { mp.next.⇐ sp.next }
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
  diff = ev.time - track.last_tick
  diff = 0 if diff < 0
  # Hier gaat het allemaal om!
  STDERR.printf "ARA:%d:diff=%d, ev.time.tick=%d, last=%d\n", __LINE__, diff, ev.time, track.last_tick
  var_value track, diff
  track.last_tick = ev.time
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
#   puts "ev.receiver_queue_id=#{ev.receiver_queue_id}, queue.id=#{@queue.id}"
#   puts "ev.time=#{ev.time.inspect}"
  return if ev.receiver_queue_id != @queue.id || !(Integer === ev.time)
#   puts "handling #{ev.type}"
  print '.'
  #         determine which track to record to
  i = ev.dest.port # id == index
  if @metronome && ev.dest == @metronome.myport
    @metronome.pattern(ev.time) if ev.type == :usr0
    return
  end
  ch = ev.channel ? ev.channel - 1 : 0
  i = i * TRACKS_PER_PORT + ch if @channel_split
  return if i >= @tracks.length
  track = @tracks[i]
  case ev.type
  when :noteon
    delta_time track, ev
    command(track, Driver::MIDI_CMD_NOTE_ON | ch)
    add_byte(track, ev.note)
    add_byte(track, ev.velocity)
  when :noteoff
    delta_time track, ev
    command(track, Driver::MIDI_CMD_NOTE_OFF | ch)
    add_byte(track, ev.note)
    add_byte(track, ev.velocity)
  when :keypress
    delta_time track, ev
    command(track, Driver::MIDI_CMD_NOTE_PRESSURE | ch)
    add_byte(track, ev.note)
    add_byte(track, ev.velocity)
  when :controller
    delta_time(track, ev)
    command(track, Driver::MIDI_CMD_CONTROL | ch)
    add_byte(track, ev.param)
    add_byte(track, ev.value & 0x7f)
  when :pgmchange
    delta_time(track, ev)
    command(track, Driver::MIDI_CMD_PGM_CHANGE | ch)
    add_byte(track, ev.value & 0x7f)
  when :chanpress
    delta_time track, ev
    command(track, Driver::MIDI_CMD_CHANNEL_PRESSURE | ch)
    add_byte(track, ev.value & 0x7f)
  when :pitchbend
    delta_time track, ev
    command(track, Driver::MIDI_CMD_BENDER | ch)
    add_byte(track, (ev.value + 8192) & 0x7f)
    add_byte(track, ((ev.value + 8192) >> 7) & 0x7f)
  when :control14
#    create two commands for MSB and LSB
    delta_time track, ev
    command(track, Driver::MIDI_CMD_CONTROL | ch)
    add_byte(track, ev.param)
    add_byte(track, (ev.value >> 7) & 0x7f)
    if ev.param < 0x20
      delta_time(track, ev)
#   running status
      add_byte(track, ev.param + 0x20)
      add_byte(track, ev.value & 0x7f);
    end
  when :nonregparam
    delta_time track, ev
    command(track, Driver::MIDI_CMD_CONTROL | ch)
    add_byte(track, Driver::MIDI_CTL_NONREG_PARM_NUM_LSB)
    add_byte(track, ev.param & 0x7f)
    delta_time(track, ev)
    add_byte(track, Driver::MIDI_CTL_NONREG_PARM_NUM_MSB)
    add_byte(track, (ev.param >> 7) & 0x7f)
    delta_time track, ev
    add_byte(track, Driver::MIDI_CTL_MSB_DATA_ENTRY)
    add_byte(track, (ev.value >> 7) & 0x7f)
    delta_time track, ev
    add_byte(track, Driver::MIDI_CTL_LSB_DATA_ENTRY)
    add_byte(track, ev.value & 0x7f)
  when :regparam
    delta_time track, ev
    command(track, Driver::MIDI_CMD_CONTROL | ch)
    add_byte(track, Driver::MIDI_CTL_REGIST_PARM_NUM_LSB)
    add_byte(track, ev.param & 0x7f)
    delta_time track, ev
    add_byte(track, Driver::MIDI_CTL_REGIST_PARM_NUM_MSB)
    add_byte(track, (ev.param >> 7) & 0x7f)
    delta_time track, ev
    add_byte(track, Driver::MIDI_CTL_MSB_DATA_ENTRY)
    add_byte(track, (ev.value >> 7) & 0x7f)
    delta_time track, ev
    add_byte(track, Driver::MIDI_CTL_LSB_DATA_ENTRY)
    add_byte(track, ev.value & 0x7f)
  when SND_SEQ_EVENT_SYSEX
    sysex = ev.value
    unless sysex.empty?
      delta_time track, ev
      if sysex.byte(0) == 0xf0 # *(unsigned char*)ev->data.ext.ptr == 0xf0)
        command track, 0xf0
        skipfirst = true
      else
        command track, 0xf7
        skipfirst = false
      end
      var_value(track, sysex.length - i)
      for b in sysex.bytes
        if skipfirst
          skipfirst = false
        else
          add_byte track, b
        end
      end
    end
  else
    return
  end
  track.used = true
end

def finish_tracks
  tick = @queue.status.tick_time
# make length of first track the recording length
  tick_track = tick - @tracks[0].last_tick
  for track in @tracks
    var_value @tracks[0], tick_track
    tick_track = 0
    add_byte track, 0xff
    add_byte track, 0x2f
    var_value track, 0
  end
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

  for track in @tracks.find_all(&:used?)
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

# UGLY: need to instance or else optparser cannot set them.
# It seems custom to make options a hash.
@metronome_source_port = nil
@metronome_weak_note = Metronome::WEAK_NOTE
@metronome_strong_note = Metronome::STRONG_NOTE
@metronome_velocity = Metronome::VELOCITY
@metronome_program = Metronome::PROGRAM
@metronome_channel = Metronome::CHANNEL

require 'optparse'
opts = OptionParser.new
opts.banner = "Usage: #$PROGRAM_NAME [options] outputfile|-"
opts.on('-h', '--help', 'this help') { puts opts.to_s; exit 1 }
opts.on('-V', '--version', 'show version') { STDERR.puts("rrecordmidi version #{SND_UTIL_VERSION_STR}"); exit }
opts.on('-l', '--list', 'list input ports') do
  puts(" Port    Client name                      Port name")
  for portname, port in @sequencer.ports
    next if port.system? # don't show system timer and announce ports
                            #    port must understand MIDI messages
    next unless port.type?(:midi_generic) && port.capability?(:read, :subscription_read)
    #  we need both READ and SUBS_READ
    printf("%3d:%-3d  %-32.32s %s\n", port.client_id, port.port, port.client.name, portname)
  end
  exit 0
end

opts.on('-p', '--port=VAL', 'source port(s)') do |port|
#  parses one or more comma separated port addresses from the string
  @source_ports = port.split(',').map { |port_name| @sequencer.parse_address port_name }
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

opts.on('-m', '--metronome=VAL', 'play a metronome signal') do |portspec|
  @metronome_source_port = @sequencer.parse_address(portspec)
end
opts.on('--metronome-strong-note=VAL', "key for the main beat (#{Metronome::STRONG_NOTE})") do |v|
  raise OptionParser::InvalidArgument.new("Invalid note (#{v})") unless (1 .. 127) === v
  @metronome_strong_note = v
end
opts.on('--metronome-weak-note=VAL', "key for the sub beats (#{Metronome::WEAK_NOTE})") do |v|
  raise OptionParser::InvalidArgument.new("Invalid note (#{v})") unless (1 .. 127) === v
  @metronome_weak_note = v
end
opts.on('--metronome-channel=VAL', "channel for the metronome (#{Metronome::CHANNEL})") do |v|
  raise OptionParser::InvalidArgument.new("Invalid channel (#{v})") unless (1 .. 16) === v
  @metronome_channel = v
end
opts.on('--metronome-volume=VAL', "volume for the metronome (#{Metronome::VELOCITY})") do |v|
  raise OptionParser::InvalidArgument.new("Invalid volume (#{v})") unless (1 .. 127) === v
  @metronome_velocity = v
end
# just a program is useless on most modern keyboards
opts.on('--metronome-program=VAL', "program for the metronome (#{Metronome::PROGRAM})") do |v|
  raise OptionParser::InvalidArgument.new("Invalid program (#{v})") unless (1 .. 127) === v
  @metronome_program = v
end
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

#       open sequencer
require_relative 'sequencer'
include RRTS
Sequencer.new('rrecordmidi') do |seq|
  @sequencer = seq # export ....
  @client = @sequencer.client
  filename = opts.parse(ARGV)
  fail("Please specify a file to record to.\n") if filename.empty?
  help if filename.length > 1
  filename = filename[0]

  @ticks = @smpte_timing ? 40 : 384 unless @ticks
  @ticks = 0xff if @smpte_timing && @ticks > 0xff
  fail("Please specify a source port with --port.") if @source_ports.empty?

  # MIDI RP-019 says we need at least one track per port
  # Allocate one track for each possible channel.
  # Empty tracks won't be written to the file.
  @tracks = Array.new(@source_ports.length * (@channel_split ? TRACKS_PER_PORT : 1)) { Smf_track.new }
  create_queue
  create_ports
  if @metronome_source_port
    @metronome = Metronome.new(@queue, @metronome_source_port,
                               channel: @metronome_channel,
                               velocity: @metronome_velocity,
                               weak_note: @metronome_weak_note, strong_note: @metronome_strong_note,
                               program: @metronome_program, ts_num: @ts_num, ts_div: @ts_div,
                               port: @source_ports.length)
  end
  connect_ports
  record_port_numbers if @source_ports.length > 1

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
  open(filename == '-' ? 1 : filename, "wb:binary") do |file|
    @file = file
    @queue.start # @sequencer.start_queue(@queue).
    @sequencer.drain_output
    @sequencer.nonblock

    if @metronome
      @metronome.set_program
      @metronome.pattern 0
    end

    Signal.trap('INT') { @stop = true }
    Signal.trap('TERM') { @stop = true }

    # FIXME. this is a busy loop. Why not just use blocking ???
    npfds = @sequencer.poll_descriptors_count(POLLIN);
    until @stop do
    #   trace do
      descriptors = @sequencer.poll_descriptors(npfds, POLLIN);
      revents = @sequencer.poll_descriptors_revents(descriptors)
    #   end
      more = true
      until @stop || !more
        (event, more = @sequencer.event_input) or break
        record_event event
      end
    end
    # trace
    finish_tracks
    write_file
  end
end
