#!/usr/bin/ruby -w
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

# First of all we create a parser that builds a parsetree
# aka nodetree. But in our case it just a linear Array of MidiEvents.
# With one complication: there are tracks (or parts/voices)

# My idea of a track was a single channel input.
# However it seems more that it is a complete song.
# Well that depends on the rrecordmidi param --split-channels!!
#
# IDEA: make Track < Array
class Track
  private
  def initialize chunk_or_block = nil, params = nil
    @owner = chunk_or_block
    @events = nil
#     @end_tick = 0 # length of this track, in ticks  WE DO NOT CARE
    @channel = nil # as originally recorded. A track can have at most one channel
    @portnr = nil # basicly index when recorded. Need not to match replay
    @portname = nil # as originally recorded
    @time_signature = [4, 4] # ie 4/4
    @ticks_per_beat = 384
    @key = :C; # then :'C#', :D .... :B
    @sequencenr = 0
    @description = @copyright = @name = @voicename = @lyrics = ''
    @marker = ''
    @cue_point = ''
    set(params) if params
  end

  def handleNoteOff event
    # locate the last NoteOn in @events with the same value.
    i = @events.length
    v = event.value
    i -= 1 while i > 0 && @events[i - 1].value != v
    return false if i == 0
    i -= 1
    on_ev = @events[i]
    @events[i] = NoteEvent.new(event.channel, v, on_ev.velocity,
                               duration: event.tick - on_ev.tick, off_velocity: event.velocity,
                               source: event.source, time: on_ev.time)
    return true
  end

  public
  attr_accessor :channel, :end_tick
  attr :owner, :events
  attr_accessor :time_signature, :ticks_per_beat, :portnr
  attr_accessor :description, :copyright, :name, :voicename, :lyrics, :marker
  attr_accessor :cue_point

   # store an event
  def << event
    case event
    when ControllerEvent
      if event.param == :bank_lsb
        last = @events.last
        # do not collapse these to a single if!!
        puts "LSB_BANK detected (32), last.type=#{last && last.type}, last.param=#{last && last.param}"
        if last && last.type == :controller && last.param == :bank
          last.value = [last.value, event.value]
          return self
        end
      end
    when ProgramChangeEvent
      last = @events.last
      puts "PGMCHANGE, last.param=#{last && last.param}"
      if last && last.param == :bank
        puts "collapse MSB_BANK + PGMCHANGE"
        value = Array === last.value ? last.value : [last.value]
        value << event.value
        event.value = value
        @events[-1] = event
        return
      end
    when NoteOnEvent
      return if event.velocity == 0 && handleNoteOff(event)
    when NoteOffEvent
      handleNoteOff(event) and return self
    end
    @events << event
    self
  end

  def set params
    for k, v in params
      case k
      when :seqnr, :sequencenr then @sequencenr = v
      when :portnr then @portnr = v
      when :channel then @channel = v
      when :owner then @owner = v
      else raise RRTSError.new("illegal param '#{k}' for track")
      end
    end
    @events ||= []
  end

  def each(&block)
    @events.each(&block)
  end

  def [](i)
    @events[i]
  end

  def length
    @events.length
  end
end # Track

# Let's use 'block' for a specific timeline-part of some bars.
# Blocks can be nested and stuck together.
# While a chunk describes a piece without any internal ordering
class Soundchunk
  private
  def initialize time_division
    @tracks = {}
    if (time_division & 0x8000) != 0 # smpte_timing
      @tempo = Tempo.new(0x80 - ((time_division >> 8) & 0x7f), smpte_timing: true,
                         ticks: time_division & 0xff)
    else
      @tempo = Tempo.new(120, ticks: time_division)
    end
    @template_track = nil
    @last_tick = nil
  end

  public

  attr :tempo, :tracks, :source_clientname, :source_portname

  # for each recorded group of metadata we store that in this 'template'
  # it would be better if we made sure to apply the template
  # currently it assumes metadata is in front of the track!!! FIXME
  attr_accessor :template_track, :last_tick

  # returns (may create) a track for this seq, port and channel
  def [](seqnr, portnr, channel)
    key = "#{seqnr}:#{portnr}:#{channel}"
    t = @tracks[key] and return t
    t = @template_track.dup
    t.set(owner: self, seqnr: seqnr, portnr: portnr, channel: channel)
    @tracks[key] = t
  end

  def each(&block)
    @tracks.values.each(&block)
  end
end # class Soundchunk

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
  def initialize file_name
    @file_name = file_name
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
    (a + (b << 8) + (c << 16) + (d << 24)).tap{|v|puts "read_32_le->#{v}"}
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
    puts "read_int -> #{value}"
    value
  end

  # reads a variable-length number, at most 4 bytes.
  # the end is indicated by the absense of bit 8 (0x80).
  # This may however be the end of the file
  def read_var
    c = read_byte or return nil  # eof
    value = c & 0x7f
    return value.tap{|v|puts"read_var->#{v}"} if (c & 0x80) == 0
    c = read_byte or invalid
    value = (value << 7) | (c & 0x7f)
    return value.tap{|v|puts"read_var->#{v}"} if (c & 0x80) == 0
    c = read_byte or invalid
    value = (value << 7) | (c & 0x7f)
    return value.tap{|v|puts"read_var->#{v}"} if (c & 0x80) == 0
    c = read_byte or invalid
    ((value << 7) | c).tap{|v|puts"read_var->#{v}"}
  end

  def read_fixed bytes
    value = 0
    bytes.times do
      c = read_byte or invalid
      value = (value << 7) | (c & 0x7f)
    end
    puts "read_fixed->#{value}"
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
  def read_track chunk, track_end_pos
    tick = 0
    last_cmd = nil
    # metadata:
    sequencenr = 0
    portnr = 0
    channel = 0

    # track solely for storing metadata, only usefull if this arrives before
#     # any other stuff!
    chunk.template_track = Track.new
    #  the current file position is after the track ID and length
    while @file.pos < track_end_pos do
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
      ch = (cmd & 0x0f) + 1 # but not always. And MidiEvent uses 1..16!
#       if fixed_channel
#         puts "ALERT: fixed_channel=#{fixed_channel}, ch=#{ch}" if fixed_channel != ch
#       else
#         fixed_channel = ch
#       end
      event = nil
      case status
      when 0x8 # NoteOff
        value = read_byte & 0x7f
        read_byte
        puts "#{File.basename(__FILE__)}:#{__LINE__}:NoteOffEvent"
        event = NoteOffEvent.new ch, value
      when 0x9, 0xa  # NoteOn KeyPress
#         track.channel = ch
        value = read_byte & 0x7f
        vel = read_byte & 0x7f
#         puts "#{File.basename(__FILE__)}:#{__LINE__}:NoteOnEvent"
        event = (status == 0x9 ? NoteOnEvent : KeypressEvent).new ch, value, vel
      when 0xb # Controller
        param = read_byte & 0x7f
        value = read_byte & 0x7f
        event = ControllerEvent.new ch, param, value
      when 0xe
        event = PitchbendEvent.new ch, read_fixed(2) - 0x2000
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
          # I assume here that normally sequencenr + portnr are in front of the file.
          case c
          when 0x21  # port number
            invalid if len < 1
            chunk.template_track.portnr = portnr = read_byte # ????? % @port_count
            # This is the recorded port number. See rrecordmidi.
            # But since this is basicly an internal number it is rather useless.
            # What we need is the name!!
            skip(len - 1) if len > 1
#             puts "#{File.basename(__FILE__)}:#{__LINE__}:Received META event with portnr: #{port}"
          when 0x2f  # end of track
            chunk.last_tick = tick
            @file.pos = track_end_pos
            return
          when 0x51 # tempo
            invalid if len < 3
            if chunk.tempo.smpte_timing? # SMPTE timing doesn't change
              skip len
            else
              a = read_byte
              b = read_byte
              c = read_byte
              # this is microseconds per q.   so 120qpm => 60_000ms/120q = 500mspq
              # FIXME: I doubt TempoEvent knows anything about mspq???
              # It must be converted to what TempoEvent expects...
              # and what about the queue?
              chunk.tempo.tempo = usec_q = (a << 16) + (b << 8) + c
              event = TempoEvent.new 0, usec_q
              skip(len - 3) if len > 3
            end
          when 0x0 # sequence nr of the track
            invalid unless len == 1
            chunk.template_track.sequencenr = sequencenr = read_int(2)
          when 0x1 # description
            chunk.template_track.description = @file.read(len)
          when 0x2 # copyright
            chunk.template_track.copyright = @file.read(len)
          when 0x3 # name
            chunk.template_track.name = @file.read(len)
          when 0x4 # voicename
            chunk.template_track.voicename = @file.read(len)
          when 0x5 # lyrics
            chunk.template_track.lyrics = @file.read(len)
          when 0x6 # lyrics
            chunk.template_track.marker = @file.read(len)
          when 0x7 # cue point
            chunk.template_track.cue_point = @file.read(len)
          when 0x58 # time signature
            invalid unless len == 4
            numerator = read_byte
            denominator = read_byte
            ticks_per_beat = read_byte
            skip 1  # last byte == ????
            chunk.template_track.time_signature = numerator, denominator
            chunk.template_track.ticks_per_beat = ticks_per_beat
          when 0x59 # key signature
            invalid unless len == 2
            sf = read_byte # 0 == C, 1 == G, 2 == D
                # but it says -7 is B so is that 11 now ???? This is stupid
                # -128 = 0xff -127  = 0xfe
                # so -7 should be 135 up to -1 which is 128
            sf = 128 - sf if sf > 127  # and now F = -1 (at least I hope so)
            # the next byte is 0 for Major.
            chunk.template_track.key = [:C, :G, :D, :A, :E, :B, :'F#', :F, :'A#', :'D#', :'G#', :'C#'][sf], read_byte == 0
          else # ignore all other meta events (ie 7f, sequencer specific)
            skip len
          end
        else
          invalid
        end
      else
        invalid
      end
      if event
#       event.source = @source_port too early Not interesting Plainly wrong
        event.time = tick
        chunk[sequencenr, portnr, event.channel || 0] << event
      end
#       puts "#{File.basename(__FILE__)}:#{__LINE__}:Adding event to track #{track}"
    end
  end

  # read an entire MIDI file
  def read_smf
    #    int header_len, type, time_division, i, err;
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
    chunk = Soundchunk.new(time_division)
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
      read_track(chunk, @file.pos + len)
    end
    chunk
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
      skip((len + 1) & ~1)
    end
    # the "data" chunk must contain data in SMF format
    raise RRTSError.new("#@file_name: invalid file format") unless read_id == MTHD
    read_smf
  end



  public

  # Soundblock MidifileParser#run
  def run
    File.open(@file_name == '-' ? 0 : @file_name, "rb:binary") do |file|
      @file = file
      file_offset = 0
      id = read_id
#       puts "#{File.basename(__FILE__)}:#{__LINE__}:id=#{'%x' % id},MTHD=#{'%x' % MTHD},RIFF=#{'%x' % RIFF}"
#       RRTS::trace {
      return case
      when MTHD then read_smf
      when RIFF then read_riff
      else fail("#@file_name is not a Standard MIDI File")
      end
#       }
    end
  end
end # class MidifileParser

=begin

plays a chunk
We now have tracks to be played 'merged'. Each track is an array of events.
All tracks are in chunk.tracks.values.

So we must keep track of what goes first. The crude method would be to
check all tracks for there first note to play. Which is not the first note
of the track. So we need an enumerator per track.
1)   1 1            6                    41
2)      2  3  4
3)   1  2 2         6 7                 40
4)                                            234 ...

   Enumerator has no current or peek, only next.
   Oh, in 1.9.1 it has peek.
   In the example above track 4 is not really interesting until far in the
   future.

   So we can then store the enumerators in a priority queue. Where the peek
   (which is I assume the next, without removing it) time makes the order,
   followed by channel to keep chords lined out if they are over several channels.

   BinTree
   Top.left  left >= self
   Top.right right >= self

   (1)   ->   (1(2)) -> (1(2)(1)) -> (1(2(234))(1))
   When discarding the top the next time comes forward. If it is still
   less or equal than both subbranches, we don't have to do anything.
   Otherwise the treetrunk is cut off and either the left or the right
   (the smallest) becomes the new trunk after which we store the top of
   the losing branch in the new top. However that top may have branches too.

   Ordinarily you cannot expect more than 100 tracks playing.

   Nodes in the tree are PriorityTree for branching nodes and single
   Tracks for leaves. But it seems better to pack each track in a tree
   node, branches or not. When reordening the tree no node creation
   will be required.
=end

class Player
  private
  def initialize sequencer, ports, queue, source_port
    @sequencer, @ports, @queue, @source_port = sequencer, ports, queue, source_port
  end

  public

  # the portnr in the track actually works like an index into the output port array
  def play chunk
    require 'yaml'
#     puts "#{File.basename(__FILE__)}:#{__LINE__}:chunk=#{chunk.inspect}"  A MESS!
    File.open("./y.yaml", "w") { |file| YAML.dump(chunk, file) }
    require_relative 'prioqueue'
    tracks = PriorityTree.new
    # Interesting enough it would be much simpler if note-on and note-off events were
    # in the queue, and not Note-events.
    on_notes = {}
    for track in chunk
      # we must enqueue the track and not the events, otherwise I no longer
      # know which tracks belongs to a dequeued event.
      tracks.enqueue track
    end
    # interpret and set tempo
    @queue.tempo = chunk.tempo
    @sequencer.start_queue @queue
    event, track = tracks.dequeue
    #       The queue won't be started until the START_QUEUE event is
    #       actually drained to the kernel, which is exactly what we want.
    while event
      # This is ugly as these parameters should be added to the lowlevel ev.
      # and not to event.  Can't I pass them to output_event?  FIXME
      event.sender_queue = @queue  # not queue=
      event.source = @source_port
#       event.flags = { :time_ticks=>true }  Default. And this is bad
      #  output the event
      destination = @ports[track.portnr % @ports.length]
      event.dest = destination unless event.dest  # Tempo event already has a destination
      print ">"
      case event
      when NoteEvent
        # Send a NoteOnEvent + NoteOffEvent instead!
        ev1 = NoteOnEvent.new(event.channel, event.note, event.velocity,
                              sender_queue: @queue,
                              source: @source_port, dest: destination,
                              tick: event.tick)
        # Sending more NoteOn events saves on the output
        # However, when removing notes in case of an interrupt, the NoteOffs are more
        # convenient (!)  Or does remove_events take velocity == 0 in consideration?
        # Let's begin by assuming it is smart...
        ev2 = NoteOnEvent.new(event.channel, event.note, 0,
                              sender_queue: @queue,
                              source: @source_port, dest: destination,
                              tick: event.tick + event.duration)
        @sequencer << ev1 << ev2
      else
        #  this blocks when the output pool has been filled
        @sequencer << event
      end
      #  make sure that the sequencer sees all our events
      @sequencer.flush  # this is inefficient, why not do it per bar or so?
      event, track = tracks.dequeue
    end
    puts
    #  schedule queue stop at end of song. NOTICE: originally placed sooner
    event = StopEvent.new @queue
    event.time = chunk.last_tick
    event.dest = @sequencer.system_timer
    event.sender_queue = @queue
    @sequencer << event
#       /*
#       * There are three possibilities how to wait until all events have
#       * been played:
#       * 1) send an event back to us (like pmidi does), and wait for it;
#       * 2) wait for the EVENT_STOP notification for our queue which is sent
#       *    by the system timer port (this would require a subscription);
#       * 3) wait until the output pool is empty.
#       * The last is the simplest.
#       */
    @sequencer.sync_output_queue
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
        soundblock = MidifileParser.new(file_name).run
        Player.new(sequencer, @options[:ports], queue, source_port).play soundblock
        # give the last notes time to die away
        sleep(@options[:end_delay]) if @options[:end_delay] > 0
      end
    end
  end
end

