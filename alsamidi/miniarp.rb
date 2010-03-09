#!/usr/bin/ruby -w

#  miniArp.c by Matthias Nagorni
# See http://www.suse.de/~mana/miniArp.c

TICKS_PER_QUARTER = 128
MAX_SEQ_LEN = 64

require_relative 'rrts'

include RRTS
include Driver

# Germans call b h
Map1 = {'c'=>0, 'd'=>2, 'e'=>4, 'f'=>5, 'g'=>7, 'a'=>9, 'b'=>11, 'h'=>11,
        'C'=>0, 'D'=>2, 'E'=>4, 'F'=>5, 'G'=>7, 'A'=>9, 'B'=>11, 'H'=>11
        }

def parse_sequence

#   FILE *f;
# char c;
  sequence = []
  sequence[0] = sequence[1] = sequence[2] = []
  File::open(@seq_filename, "r") do |file|
    @seq_len = 0
    chars = file.chars
    loop do
      c = chars.next
#       puts "#{File.basename(__FILE__)}:#{__LINE__}:read '#{c}'"
      break if c == "\n"
      sequence[2][@seq_len] = Map1[c] or fail("Bad note '#{c}'")
      c =  chars.next
      if c == '#'
        sequence[2][@seq_len] += 1
        c = chars.next
      end
#       puts "read '#{c}'"
      sequence[2][@seq_len] += 12 * c.to_i
      c = chars.next
#       puts "read '#{c}'"
      sequence[1][@seq_len] = TICKS_PER_QUARTER / c.to_i
      c = chars.next
#       puts "read '#{c}'"
      sequence[0][@seq_len] = TICKS_PER_QUARTER / c.to_i
      @seq_len += 1
#       puts "seq_len now is #@seq_len"
    end
  end
  @sequence = sequence
end

def set_tempo
  queue_tempo = queue_tempo_malloc
  tempo = 60_000_000 / (@bpm * TICKS_PER_QUARTER) * TICKS_PER_QUARTER
  queue_tempo.tempo = tempo
  queue_tempo.ppq = TICKS_PER_QUARTER
  @queue.tempo = queue_tempo
end

def arpeggio
  for l1 in (0...@seq_len)
    dt = (l1 % 2 == 0) ? @swing.to_f / 16384.0 : @swing.to_f / 16384.0
    ev = ev_malloc
    ev.clear
#     puts "sequence=#{@sequence.inspect}"
    ev.set_note(0, @sequence[2][l1] + @transpose, 127, @sequence[1][l1])
    ev.schedule_tick @queue, 0, @tick
    ev.source = @port_out
    ev.set_subs
    @sequencer.event_output_direct ev
    @tick += (@sequence[0][l1].to_f * (1.0 + dt)).to_i
  end
  ev.clear
  ev.type = SND_SEQ_EVENT_ECHO
  ev.schedule_tick @queue,  0, @tick
  ev.dest = @port_in
  @sequencer.event_output_direct ev
end

def get_tick
  @queue.status.tick_time
end

def clear_queue
  remove_ev = remove_events_malloc
  remove_ev.queue = @queue
  remove_ev.condition = SND_SEQ_REMOVE_OUTPUT | SND_SEQ_REMOVE_IGNORE_OFF
  @sequencer.remove_events(remove_ev) if @sequencer   # racecondition?? Who makes it nil anyway?
end

def midi_action
  loop do
    (ev, remains = @sequencer.event_input) or break
    case ev
    when EchoEvent then arpeggio
    when NoteOnEvent
      clear_queue
      @transpose = ev.note - 60
      @tick = get_tick
      arpeggio
    when ControllerEvent
      if ev.param == MIDI_CTL_MSB_MODWHEEL # 1
        @bpm = (@bpm0.to_f * (1.0 + ev.value.to_f / 127.0)).to_i
        set_tempo
      end
    when PitchbendEvent
      @swing = ev.value.to_f
    end
    return if remains == 0 # @sequencer.event_input_pending(false) == 0
  end
end

def sigterm_exit
  STDERR.print("Closing, please wait...");
  clear_queue
  sleep 2
  @queue.stop
  @queue.free
  STDERR.puts
  exit
end

# int main(int argc, char *argv[]) {

#   int npfd, l1;
# struct pollfd *pfd;

if ARGV.length < 2
  fail "\nUsage:\nminiarp.rb <beats per minute> <sequence file>\n"
end
@bpm0 = Integer(ARGV[0])
@bpm = @bpm0
@swing = @transpose = @tick = 0
@seq_filename = ARGV[1]
sequence = parse_sequence
require_relative 'sequencer'
Sequencer.new 'miniArp' do |seq|
  @sequencer = seq
  @port_out = MidiPort.new(seq, "miniArp O", read: true, subs_read: true, application: true)
  @port_in = MidiPort.new(seq, 'miniArp I', write: true, subs_write: true, application: true)
  require_relative 'midiqueue'
  @queue = MidiQueue.new seq, 'miniArp'
  seq.client_pool_output = (@seq_len << 1) + 4
  set_tempo
  arpeggio
  @queue.start
  seq.flush
  descriptors = seq.poll_descriptors(Sequencer::PollIn)
  @transpose = @swing = @tick = 0
  Signal.trap(:INT) {  sigterm_exit }
  Signal.trap(:TERM) { sigterm_exit }
  arpeggio
  loop do
    midi_action if descriptors.poll(100_000)
  end
end